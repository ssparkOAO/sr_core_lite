import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image

TOOLS_DIR = Path(__file__).resolve().parents[1]
if str(TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(TOOLS_DIR))

from sr_core_golden import (
    conv1x1_int8,
    conv2d_same_int8,
    load_params,
    pixel_shuffle_scale2,
    qinfo_first,
    quantize_between,
    relu_int8,
)


def sr_dir():
    return Path(__file__).resolve().parents[2]


def read_output_txt(path, height, width):
    values = []
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            text = line.strip()
            if text:
                values.append(int(text))
    expected_count = height * width
    if len(values) != expected_count:
        raise ValueError(f"{path} has {len(values)} values, expected {expected_count}")
    return np.asarray(values, dtype=np.uint8).reshape((height, width))


def psnr_uint8(a, b):
    a_f = a.astype(np.float64)
    b_f = b.astype(np.float64)
    mse = np.mean((a_f - b_f) ** 2)
    if mse == 0:
        return float("inf")
    return 20.0 * np.log10(255.0 / np.sqrt(mse))


def make_software_golden(input_uint8, params):
    conv1 = params["layers"][0]
    conv3 = params["layers"][1]
    conv1_weight = np.asarray(conv1["weight"]["values"], dtype=np.int8)
    conv3_weight = np.asarray(conv3["weight"]["values"], dtype=np.int8)

    model_input = params["model_input"]
    conv1_input = conv1["input_tensor"]
    input_int8 = quantize_between(
        input_uint8.reshape((input_uint8.shape[0], input_uint8.shape[1], 1)),
        qinfo_first(model_input, "scales", 1.0),
        qinfo_first(model_input, "zero_points", 0),
        qinfo_first(conv1_input, "scales", 1.0),
        qinfo_first(conv1_input, "zero_points", 0),
        "INT8",
    )

    conv1_out, _ = conv2d_same_int8(input_int8, conv1_weight, conv1["requant"])
    conv1_out = relu_int8(conv1_out, conv1["requant"]["output_zero_point"])
    conv3_out, _ = conv1x1_int8(conv1_out, conv3_weight, conv3["requant"])
    pixshuf_out = pixel_shuffle_scale2(conv3_out)

    final_tensor = params["model_output"]
    output_uint8 = quantize_between(
        pixshuf_out,
        conv3["requant"]["output_scale"],
        conv3["requant"]["output_zero_point"],
        qinfo_first(final_tensor, "scales", conv3["requant"]["output_scale"]),
        qinfo_first(final_tensor, "zero_points", 0),
        final_tensor.get("type_name", "UINT8"),
    )
    return output_uint8.reshape((input_uint8.shape[0] * 2, input_uint8.shape[1] * 2))


def main():
    root = sr_dir()
    default_pic_dir = root / "pic" / "test_pic"
    default_result_dir = default_pic_dir / "result"

    parser = argparse.ArgumentParser(description="Evaluate Phase9.5 image-level SR output.")
    parser.add_argument("--lr-png", default=str(default_pic_dir / "butterflyx2_Y.png"))
    parser.add_argument("--hr-png", default=str(default_pic_dir / "butterfly_HR.png"))
    parser.add_argument("--rtl-output", default=str(default_result_dir / "sr_output_uint8.txt"))
    parser.add_argument("--params", default=str(root / "generated" / "sr_tflite_params.json"))
    parser.add_argument("--out-dir", default=str(default_result_dir))
    args = parser.parse_args()

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    lr_img = Image.open(args.lr_png).convert("L")
    hr_img = Image.open(args.hr_png).convert("L")
    lr_np = np.asarray(lr_img, dtype=np.uint8)
    hr_np = np.asarray(hr_img, dtype=np.uint8)

    if lr_np.shape != (128, 128):
        raise ValueError(f"LR image shape is {lr_np.shape}, expected (128, 128)")
    if hr_np.shape != (256, 256):
        raise ValueError(f"HR image shape is {hr_np.shape}, expected (256, 256)")

    resample_bilinear = getattr(Image.Resampling, "BILINEAR", Image.BILINEAR)
    bilinear_img = lr_img.resize((256, 256), resample_bilinear)
    bilinear_np = np.asarray(bilinear_img, dtype=np.uint8)

    sr_np = read_output_txt(Path(args.rtl_output), 256, 256)
    params = load_params(args.params)
    golden_np = make_software_golden(lr_np, params)

    diff = sr_np.astype(np.int16) - golden_np.astype(np.int16)
    abs_diff = np.abs(diff)
    mismatch_count = int(np.count_nonzero(diff))
    max_abs_diff = int(abs_diff.max())

    sr_psnr = psnr_uint8(sr_np, hr_np)
    bilinear_psnr = psnr_uint8(bilinear_np, hr_np)

    Image.fromarray(sr_np, mode="L").save(out_dir / "sr_output.png")
    bilinear_img.save(out_dir / "bilinear_x2.png")
    Image.fromarray(golden_np, mode="L").save(out_dir / "software_golden_output.png")

    report = []
    report.append("# Phase9.5 Image Evaluation Report")
    report.append("")
    report.append(f"LR image: `{Path(args.lr_png).name}`")
    report.append(f"HR image: `{Path(args.hr_png).name}`")
    report.append(f"RTL output txt: `{Path(args.rtl_output).name}`")
    report.append("")
    report.append("## Hardware Golden Verification")
    report.append("")
    report.append(f"- mismatch count = {mismatch_count}")
    report.append(f"- max abs diff = {max_abs_diff}")
    report.append("- PASS" if mismatch_count == 0 else "- FAIL")
    report.append("")
    report.append("## PSNR")
    report.append("")
    report.append(f"- SR vs HR PSNR = {sr_psnr:.6f} dB")
    report.append(f"- Bilinear vs HR PSNR = {bilinear_psnr:.6f} dB")
    report.append("")
    report.append("## Outputs")
    report.append("")
    report.append("- `sr_output.png`")
    report.append("- `bilinear_x2.png`")
    report.append("- `software_golden_output.png`")

    report_text = "\n".join(report) + "\n"
    (out_dir / "image_eval_report.md").write_text(report_text, encoding="utf-8")
    (out_dir / "image_eval_summary.txt").write_text(
        f"mismatch count = {mismatch_count}\n"
        f"max abs diff = {max_abs_diff}\n"
        f"SR vs HR PSNR = {sr_psnr:.6f} dB\n"
        f"Bilinear vs HR PSNR = {bilinear_psnr:.6f} dB\n"
        f"{'PASS' if mismatch_count == 0 else 'FAIL'}\n",
        encoding="utf-8",
    )

    print(report_text)


if __name__ == "__main__":
    main()
