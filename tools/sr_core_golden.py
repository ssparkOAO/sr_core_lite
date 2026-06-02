import argparse
import json
from pathlib import Path

import numpy as np


def default_project_root():
    return Path(__file__).resolve().parents[3]


def load_params(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def qinfo_first(tensor, key, default):
    values = tensor.get("quantization", {}).get(key, [])
    return values[0] if values else default


def quantize_between(q_in, in_scale, in_zp, out_scale, out_zp, dtype):
    real = in_scale * (q_in.astype(np.float64) - float(in_zp))
    q_out = np.rint(real / out_scale + float(out_zp))
    if dtype == "INT8":
        return np.clip(q_out, -128, 127).astype(np.int8)
    if dtype == "UINT8":
        return np.clip(q_out, 0, 255).astype(np.uint8)
    raise ValueError(f"Unsupported output dtype: {dtype}")


def requantize(acc, requant):
    m0 = np.asarray(requant["M0_q0_32"], dtype=np.int64)
    m1 = np.asarray(requant["M1_q32"], dtype=np.int64)
    tmp = acc.astype(np.int64) * m0.reshape((1, 1, -1)) + m1.reshape((1, 1, -1))
    rounded = (tmp >> np.int64(32)) + ((tmp & np.int64(1 << 31)) >> np.int64(31))
    return np.clip(rounded, -128, 127).astype(np.int8)


def conv2d_same_int8(input_data, weight, requant):
    h, w, cin = input_data.shape
    cout, kh, kw, weight_cin = weight.shape
    if cin != weight_cin:
        raise ValueError(f"Input Cin {cin} does not match weight Cin {weight_cin}")

    pad_y = kh // 2
    pad_x = kw // 2
    pad_value = int(requant["input_zero_point"])
    padded = np.full((h + 2 * pad_y, w + 2 * pad_x, cin), pad_value, dtype=np.int8)
    padded[pad_y : pad_y + h, pad_x : pad_x + w, :] = input_data

    acc = np.zeros((h, w, cout), dtype=np.int32)
    weight_i32 = weight.astype(np.int32)
    for y in range(h):
        for x in range(w):
            window = padded[y : y + kh, x : x + kw, :].astype(np.int32)
            for co in range(cout):
                acc[y, x, co] = np.sum(window * weight_i32[co, :, :, :], dtype=np.int32)
    return requantize(acc, requant), acc


def conv1x1_int8(input_data, weight, requant):
    h, w, cin = input_data.shape
    cout, kh, kw, weight_cin = weight.shape
    if kh != 1 or kw != 1:
        raise ValueError("conv1x1_int8 expects [cout, 1, 1, cin] weight")
    if cin != weight_cin:
        raise ValueError(f"Input Cin {cin} does not match weight Cin {weight_cin}")

    acc = np.zeros((h, w, cout), dtype=np.int32)
    weight_i32 = weight[:, 0, 0, :].astype(np.int32)
    input_i32 = input_data.astype(np.int32)
    for y in range(h):
        for x in range(w):
            for co in range(cout):
                acc[y, x, co] = np.sum(input_i32[y, x, :] * weight_i32[co, :], dtype=np.int32)
    return requantize(acc, requant), acc


def relu_int8(data, output_zero_point):
    return np.maximum(data.astype(np.int16), int(output_zero_point)).astype(np.int8)


def pixel_shuffle_scale2(input_data):
    h, w, channels = input_data.shape
    if channels % 4 != 0:
        raise ValueError("PixelShuffle scale=2 requires channels to be C*4")
    cout = channels // 4
    output = np.zeros((h * 2, w * 2, cout), dtype=input_data.dtype)
    for y in range(h):
        for x in range(w):
            for c in range(cout):
                output[2 * y + 0, 2 * x + 0, c] = input_data[y, x, c * 4 + 0]
                output[2 * y + 0, 2 * x + 1, c] = input_data[y, x, c * 4 + 1]
                output[2 * y + 1, 2 * x + 0, c] = input_data[y, x, c * 4 + 2]
                output[2 * y + 1, 2 * x + 1, c] = input_data[y, x, c * 4 + 3]
    return output


def save_array(out_dir, name, array):
    np.save(out_dir / f"{name}.npy", array)
    flat = array.reshape(-1)
    with open(out_dir / f"{name}.mem", "w", encoding="utf-8") as f:
        for value in flat:
            f.write(f"{int(value)}\n")


def squeeze_batch_axis(array):
    if array.ndim == 4 and array.shape[0] == 1:
        return array[0]
    return array


def build_runtime_input(interpreter, input_uint8, input_int8):
    input_detail = interpreter.get_input_details()[0]
    input_idx = input_detail["index"]
    input_dtype = input_detail["dtype"]

    if input_dtype == np.uint8:
        input_data = input_uint8[np.newaxis, ...].astype(np.uint8)
    elif input_dtype == np.int8:
        input_data = input_int8[np.newaxis, ...].astype(np.int8)
    else:
        raise ValueError(f"Unsupported TFLite input dtype: {input_dtype}")

    input_shape = tuple(int(v) for v in input_data.shape)
    model_input_shape = tuple(int(v) for v in input_detail["shape"])
    if input_shape != model_input_shape:
        interpreter.resize_tensor_input(input_idx, input_shape, strict=False)
        interpreter.allocate_tensors()

    return input_idx, input_data


def run_tflite_runtime(tflite_model_path, input_uint8, input_int8):
    try:
        import tensorflow as tf
    except Exception as exc:
        raise RuntimeError(
            "Failed to import TensorFlow. Please run in the target env, e.g. `conda activate tf_sr`."
        ) from exc

    interpreter = tf.lite.Interpreter(
        model_path=str(tflite_model_path),
        experimental_preserve_all_tensors=True,
    )
    interpreter.allocate_tensors()
    input_idx, input_data = build_runtime_input(interpreter, input_uint8, input_int8)

    interpreter.set_tensor(input_idx, input_data)
    interpreter.invoke()

    tensor_indices = {
        "conv1_output": 5,
        "conv3_output": 8,
        "pixel_shuffle_output": 9,
        "final_output": 12,
    }
    runtime_tensors = {}
    for name, tensor_idx in tensor_indices.items():
        runtime_tensors[name] = interpreter.get_tensor(tensor_idx)
    return runtime_tensors


def compare_tensor(runtime_tensor, reconstructed_tensor):
    runtime_cmp = squeeze_batch_axis(np.asarray(runtime_tensor))
    recon_cmp = np.asarray(reconstructed_tensor)

    result = {
        "runtime_shape": tuple(runtime_cmp.shape),
        "runtime_dtype": str(runtime_cmp.dtype),
        "reconstructed_shape": tuple(recon_cmp.shape),
        "reconstructed_dtype": str(recon_cmp.dtype),
        "exact_match": False,
        "max_abs_diff": None,
        "mismatch_count": None,
        "runtime_cmp": runtime_cmp,
        "reconstructed_cmp": recon_cmp,
        "diff_cmp": None,
    }

    if runtime_cmp.shape != recon_cmp.shape:
        return result

    runtime_i64 = runtime_cmp.astype(np.int64)
    recon_i64 = recon_cmp.astype(np.int64)
    diff = runtime_i64 - recon_i64
    mismatch_count = int(np.count_nonzero(diff))
    max_abs_diff = int(np.max(np.abs(diff))) if diff.size > 0 else 0
    exact_match = (mismatch_count == 0) and (runtime_cmp.dtype == recon_cmp.dtype)

    result["exact_match"] = bool(exact_match)
    result["max_abs_diff"] = max_abs_diff
    result["mismatch_count"] = mismatch_count
    result["diff_cmp"] = diff
    return result


def save_runtime_compare(runtime_dump_dir, name, compare_result):
    runtime_dump_dir.mkdir(parents=True, exist_ok=True)
    np.save(runtime_dump_dir / f"{name}_runtime.npy", compare_result["runtime_cmp"])
    np.save(runtime_dump_dir / f"{name}_reconstructed.npy", compare_result["reconstructed_cmp"])

    if compare_result["diff_cmp"] is None:
        diff = np.full(compare_result["runtime_cmp"].shape, np.iinfo(np.int64).min, dtype=np.int64)
    else:
        diff = compare_result["diff_cmp"]
    np.save(runtime_dump_dir / f"{name}_diff.npy", diff)


def make_input(params, height, width, seed, input_npy):
    model_input = params["model_input"]
    model_input_scale = qinfo_first(model_input, "scales", 1.0)
    model_input_zp = qinfo_first(model_input, "zero_points", 0)

    conv1_input = params["layers"][0]["input_tensor"]
    conv1_scale = qinfo_first(conv1_input, "scales", 1.0)
    conv1_zp = qinfo_first(conv1_input, "zero_points", 0)

    if input_npy:
        input_uint8 = np.load(input_npy)
        input_uint8 = input_uint8.reshape((height, width, 1)).astype(np.uint8)
    else:
        rng = np.random.default_rng(seed)
        input_uint8 = rng.integers(0, 256, size=(height, width, 1), dtype=np.uint8)

    input_int8 = quantize_between(
        input_uint8,
        model_input_scale,
        model_input_zp,
        conv1_scale,
        conv1_zp,
        "INT8",
    )
    return input_uint8, input_int8


def main():
    root = default_project_root()
    parser = argparse.ArgumentParser(description="Generate small-patch SR core golden data.")
    parser.add_argument(
        "--params",
        default=str(root / "model_lite" / "sr_core" / "generated" / "sr_tflite_params.json"),
        help="Path to sr_tflite_params.json.",
    )
    parser.add_argument("--height", type=int, default=8, help="LR patch height.")
    parser.add_argument("--width", type=int, default=8, help="LR patch width.")
    parser.add_argument("--seed", type=int, default=1, help="Random seed for generated input.")
    parser.add_argument("--input-npy", default="", help="Optional uint8 input npy path.")
    parser.add_argument(
        "--out-dir",
        default=str(root / "model_lite" / "sr_core" / "generated" / "golden"),
        help="Output directory.",
    )
    parser.add_argument(
        "--verify-with-tflite",
        action="store_true",
        help="Run TFLite runtime path and compare runtime tensors with reconstructed tensors.",
    )
    parser.add_argument(
        "--tflite-model",
        default=str(root / "model_lite" / "sr_core" / "tools" / "Bilinear_PP_v5_test_qat.tflite"),
        help="Path to runtime verification TFLite model.",
    )
    parser.add_argument(
        "--runtime-dump-dir",
        default=str(root / "model_lite" / "sr_core" / "generated" / "runtime_dump"),
        help="Output directory for runtime/reconstructed/diff tensor dumps.",
    )
    args = parser.parse_args()

    params = load_params(args.params)
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    conv1 = params["layers"][0]
    conv3 = params["layers"][1]
    conv1_weight = np.asarray(conv1["weight"]["values"], dtype=np.int8)
    conv3_weight = np.asarray(conv3["weight"]["values"], dtype=np.int8)

    input_uint8, input_int8 = make_input(
        params=params,
        height=args.height,
        width=args.width,
        seed=args.seed,
        input_npy=args.input_npy,
    )

    conv1_out, conv1_acc = conv2d_same_int8(input_int8, conv1_weight, conv1["requant"])
    conv1_out = relu_int8(conv1_out, conv1["requant"]["output_zero_point"])

    conv3_out, conv3_acc = conv1x1_int8(conv1_out, conv3_weight, conv3["requant"])
    pixshuf_out = pixel_shuffle_scale2(conv3_out)

    final_tensor = params["model_output"]
    depth_scale = conv3["requant"]["output_scale"]
    depth_zp = conv3["requant"]["output_zero_point"]
    final_scale = qinfo_first(final_tensor, "scales", depth_scale)
    final_zp = qinfo_first(final_tensor, "zero_points", 0)
    output_uint8 = quantize_between(
        pixshuf_out,
        depth_scale,
        depth_zp,
        final_scale,
        final_zp,
        final_tensor.get("type_name", "UINT8"),
    )

    save_array(out_dir, "input_uint8", input_uint8)
    save_array(out_dir, "input_int8_for_core", input_int8)
    save_array(out_dir, "conv1_acc_int32", conv1_acc)
    save_array(out_dir, "conv1_out_int8", conv1_out)
    save_array(out_dir, "conv3_acc_int32", conv3_acc)
    save_array(out_dir, "conv3_out_int8", conv3_out)
    save_array(out_dir, "pixel_shuffle_out_int8", pixshuf_out)
    save_array(out_dir, "output_uint8", output_uint8)

    print(f"Wrote golden data to: {out_dir}")
    print(f"LR input shape: {input_uint8.shape}")
    print(f"Conv1 output shape: {conv1_out.shape}")
    print(f"Conv3 output shape: {conv3_out.shape}")
    print(f"PixelShuffle output shape: {pixshuf_out.shape}")
    print(f"Final uint8 output shape: {output_uint8.shape}")

    if args.verify_with_tflite:
        runtime_tensors = run_tflite_runtime(
            tflite_model_path=Path(args.tflite_model),
            input_uint8=input_uint8,
            input_int8=input_int8,
        )
        reconstructed_tensors = {
            "conv1_output": conv1_out,
            "conv3_output": conv3_out,
            "pixel_shuffle_output": pixshuf_out,
            "final_output": output_uint8,
        }

        runtime_dump_dir = Path(args.runtime_dump_dir)
        print(f"Runtime verification enabled, dumping to: {runtime_dump_dir}")
        for name in ["conv1_output", "conv3_output", "pixel_shuffle_output", "final_output"]:
            compare_result = compare_tensor(runtime_tensors[name], reconstructed_tensors[name])
            save_runtime_compare(runtime_dump_dir, name, compare_result)

            print(f"[{name}]")
            print(f"  runtime shape: {compare_result['runtime_shape']}, dtype: {compare_result['runtime_dtype']}")
            print(
                "  reconstructed shape: "
                f"{compare_result['reconstructed_shape']}, dtype: {compare_result['reconstructed_dtype']}"
            )
            print(f"  exact match: {compare_result['exact_match']}")
            print(f"  max abs diff: {compare_result['max_abs_diff']}")
            print(f"  mismatch count: {compare_result['mismatch_count']}")


if __name__ == "__main__":
    main()
