import argparse
import json
from pathlib import Path

import numpy as np

from tflite_flatbuffer import TFLiteModel


def default_project_root():
    return Path(__file__).resolve().parents[3]


def to_builtin(value):
    if isinstance(value, np.ndarray):
        return value.tolist()
    if isinstance(value, (np.integer,)):
        return int(value)
    if isinstance(value, (np.floating,)):
        return float(value)
    return value


def quant_info(tensor):
    q = tensor["quantization"]
    return {
        "scale": [float(v) for v in q["scales"]],
        "zero_point": [int(v) for v in q["zero_points"]],
        "quantized_dimension": int(q["quantized_dimension"]),
    }


def first_or_default(values, default):
    return values[0] if values else default


def calc_requant_params(input_tensor, weight_tensor, output_tensor, bias_values, weight_values):
    input_scale = float(first_or_default(input_tensor["quantization"]["scales"], 1.0))
    input_zp = int(first_or_default(input_tensor["quantization"]["zero_points"], 0))
    output_scale = float(first_or_default(output_tensor["quantization"]["scales"], 1.0))
    output_zp = int(first_or_default(output_tensor["quantization"]["zero_points"], 0))

    weight_scales = weight_tensor["quantization"]["scales"]
    if len(weight_scales) == 1:
        weight_scales = [float(weight_scales[0])] * weight_values.shape[0]
    weight_scales = [float(v) for v in weight_scales]

    a2 = np.sum(weight_values.astype(np.int32).reshape(weight_values.shape[0], -1), axis=1)
    z1a2 = np.int64(input_zp) * a2.astype(np.int64)

    m = np.array(
        [input_scale * ws / output_scale for ws in weight_scales],
        dtype=np.float64,
    )
    m0 = np.floor(m * (1 << 32)).astype(np.uint64)
    m1 = m0.astype(np.int64) * (bias_values.astype(np.int64) - z1a2.astype(np.int64))
    m1 = m1 + (np.int64(output_zp) << np.int64(32))

    return {
        "input_scale": input_scale,
        "input_zero_point": input_zp,
        "output_scale": output_scale,
        "output_zero_point": output_zp,
        "weight_scale": weight_scales,
        "M_float": m.tolist(),
        "M0_q0_32": [int(v) for v in m0],
        "a2_sum_weight": [int(v) for v in a2],
        "Z1a2": [int(v) for v in z1a2],
        "M1_q32": [int(v) for v in m1],
    }


def write_mem(path, values):
    flat = np.asarray(values).reshape(-1)
    with open(path, "w", encoding="utf-8") as f:
        for value in flat:
            f.write(f"{int(value)}\n")


def write_coe(path, values):
    flat = np.asarray(values).reshape(-1)
    with open(path, "w", encoding="utf-8") as f:
        f.write("memory_initialization_radix=10;\n")
        f.write("memory_initialization_vector=\n")
        for idx, value in enumerate(flat):
            sep = "," if idx != flat.size - 1 else ";"
            f.write(f"{int(value)}{sep}\n")


def write_text(path, text):
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)


def write_layer_files(out_dir, layer):
    name = layer["name"]
    weight = np.asarray(layer["weight"]["values"], dtype=np.int8)
    bias = np.asarray(layer["bias"]["values"], dtype=np.int32)
    m0 = np.asarray(layer["requant"]["M0_q0_32"], dtype=np.uint64)
    m1 = np.asarray(layer["requant"]["M1_q32"], dtype=np.int64)

    write_mem(out_dir / f"{name}_weight.mem", weight)
    write_mem(out_dir / f"{name}_bias.mem", bias)
    write_mem(out_dir / f"{name}_m0.mem", m0)
    write_mem(out_dir / f"{name}_m1.mem", m1)

    write_coe(out_dir / f"{name}_weight.coe", weight)
    write_coe(out_dir / f"{name}_bias.coe", bias)
    write_coe(out_dir / f"{name}_m0.coe", m0)
    write_coe(out_dir / f"{name}_m1.coe", m1)


def extract_layers(model):
    conv_ops = model.conv_operators()
    if len(conv_ops) < 2:
        raise RuntimeError(f"Expected at least 2 CONV_2D ops, found {len(conv_ops)}")

    layers = []
    for layer_idx, op in enumerate(conv_ops[:2]):
        input_idx, weight_idx, bias_idx = op["inputs"][:3]
        output_idx = op["outputs"][0]
        input_tensor = model.tensors[input_idx]
        weight_tensor = model.tensors[weight_idx]
        bias_tensor = model.tensors[bias_idx]
        output_tensor = model.tensors[output_idx]

        weight = model.tensor_data(weight_idx)
        bias = model.tensor_data(bias_idx)
        if weight is None or bias is None:
            raise RuntimeError(f"Missing weight or bias data in conv layer {layer_idx}")

        layer_name = "conv1" if layer_idx == 0 else "conv3"
        layer = {
            "name": layer_name,
            "op_index": op["index"],
            "input_tensor": input_tensor,
            "output_tensor": output_tensor,
            "weight": {
                "tensor": weight_tensor,
                "values": weight.astype(np.int8).tolist(),
                "shape": list(weight.shape),
                "layout": "[cout, kh, kw, cin]",
            },
            "bias": {
                "tensor": bias_tensor,
                "values": bias.astype(np.int32).tolist(),
                "shape": list(bias.shape),
            },
            "requant": calc_requant_params(
                input_tensor=input_tensor,
                weight_tensor=weight_tensor,
                output_tensor=output_tensor,
                bias_values=bias.astype(np.int32),
                weight_values=weight.astype(np.int8),
            ),
        }
        layers.append(layer)
    return layers


def build_report(model, layers):
    input_tensor = model.tensors[model.inputs[0]]
    output_tensor = model.tensors[model.outputs[0]]
    return {
        "source_tflite": str(model.path),
        "model_input": input_tensor,
        "model_output": output_tensor,
        "operators": model.operators,
        "layers": layers,
        "notes": [
            "M0 is floor((input_scale * weight_scale / output_scale) * 2^32).",
            "M1 is M0 * (bias - input_zero_point * sum(weight)) + (output_zero_point << 32).",
            "Use the same TFLite file for weight, bias, scale, zero point, M0, and M1.",
        ],
    }


def build_hw_summary(model, layers):
    input_tensor = model.tensors[model.inputs[0]]
    output_tensor = model.tensors[model.outputs[0]]

    conv1 = layers[0]
    conv3 = layers[1]

    conv1_weight_shape = conv1["weight"]["shape"]
    conv3_weight_shape = conv3["weight"]["shape"]

    output_const_tensor = model.tensors[1]
    output_const_data = model.tensor_data(1)
    output_const_value = None if output_const_data is None else int(output_const_data.reshape(-1)[0])

    hardware_blocks = [
        {
            "stage": 0,
            "name": "input_quantize",
            "tflite_ops": ["QUANTIZE"],
            "tensor_flow": "tensor 0 -> tensor 4",
            "hardware_action": "uint8 input to int8 input conversion",
            "where_to_do": "PS preferred, PL optional",
            "need_separate_pl_layer": False,
            "note": "This is input formatting, not a convolution layer.",
        },
        {
            "stage": 1,
            "name": "conv1",
            "tflite_ops": ["CONV_2D"],
            "tensor_flow": "tensor 4 -> tensor 5",
            "hardware_action": "3x3 conv + bias + requant + ReLU",
            "where_to_do": "PL core",
            "need_separate_pl_layer": True,
            "weight_shape": conv1_weight_shape,
            "bias_shape": conv1["bias"]["shape"],
            "fused_activation": "RELU",
            "need_extra_relu_layer": False,
            "note": "Conv1 output already includes fused ReLU in TFLite runtime.",
        },
        {
            "stage": 2,
            "name": "conv3",
            "tflite_ops": ["CONV_2D"],
            "tensor_flow": "tensor 5 -> tensor 8",
            "hardware_action": "1x1 conv + bias + requant",
            "where_to_do": "PL core",
            "need_separate_pl_layer": True,
            "weight_shape": conv3_weight_shape,
            "bias_shape": conv3["bias"]["shape"],
            "fused_activation": "NONE",
            "need_extra_relu_layer": False,
            "note": "This layer is plain convolution. No fused ReLU after conv3.",
        },
        {
            "stage": 3,
            "name": "pixel_shuffle",
            "tflite_ops": ["DEPTH_TO_SPACE"],
            "tensor_flow": "tensor 8 -> tensor 9",
            "hardware_action": "scale=2 PixelShuffle / Depth-to-Space",
            "where_to_do": "PL core",
            "need_separate_pl_layer": True,
            "need_mac": False,
            "note": "Data rearrangement only. No multiplier and no MAC.",
        },
        {
            "stage": 4,
            "name": "output_clip",
            "tflite_ops": ["MINIMUM", "RELU"],
            "tensor_flow": "tensor 9 -> tensor 11",
            "hardware_action": "clip output to valid int8 range before final output quantize",
            "where_to_do": "PL preferred",
            "need_separate_pl_layer": True,
            "clip_const_tensor": 1,
            "clip_const_value": output_const_value,
            "note": "MINIMUM with constant 127 then RELU. This is equivalent to clipped ReLU style output limiting.",
        },
        {
            "stage": 5,
            "name": "output_quantize",
            "tflite_ops": ["QUANTIZE"],
            "tensor_flow": "tensor 11 -> tensor 12",
            "hardware_action": "int8 output to final uint8 output format conversion",
            "where_to_do": "PL or PS",
            "need_separate_pl_layer": False,
            "note": "This is final output formatting, not a MAC layer.",
        },
    ]

    return {
        "source_tflite": str(model.path),
        "model_input": {
            "tensor_index": input_tensor["index"],
            "dtype": input_tensor["type_name"],
            "shape_signature": input_tensor["shape_signature"],
            "quantization": quant_info(input_tensor),
        },
        "model_output": {
            "tensor_index": output_tensor["index"],
            "dtype": output_tensor["type_name"],
            "shape_signature": output_tensor["shape_signature"],
            "quantization": quant_info(output_tensor),
        },
        "hardware_takeaway": {
            "pl_core_layers_to_build_now": [
                "conv1: 3x3 conv + bias + requant + fused ReLU",
                "conv3: 1x1 conv + bias + requant",
                "pixel_shuffle: Depth-to-Space scale=2",
                "output_clip: MINIMUM + RELU can be merged as one output clamp block",
            ],
            "layers_not_needed_as_standalone_blocks": [
                "No separate ReLU block after conv1 because it is fused into conv1.",
                "Input QUANTIZE and final QUANTIZE are format conversion blocks, not convolution layers.",
            ],
            "recommended_pl_pipeline": [
                "input_int8",
                "conv1 (3x3) + requant + ReLU",
                "conv3 (1x1) + requant",
                "pixel shuffle",
                "output clip",
                "final uint8 format conversion",
            ],
        },
        "hardware_blocks": hardware_blocks,
    }


def render_hw_summary_html(summary):
    rows = []
    for block in summary["hardware_blocks"]:
        rows.append(
            "<tr>"
            f"<td>{block['stage']}</td>"
            f"<td><code>{block['name']}</code></td>"
            f"<td>{', '.join(block['tflite_ops'])}</td>"
            f"<td>{block['hardware_action']}</td>"
            f"<td>{block['where_to_do']}</td>"
            f"<td>{'Yes' if block['need_separate_pl_layer'] else 'No'}</td>"
            f"<td>{block['note']}</td>"
            "</tr>"
        )

    pipeline_lines = "".join(
        f"<li><code>{item}</code></li>" for item in summary["hardware_takeaway"]["recommended_pl_pipeline"]
    )
    now_lines = "".join(
        f"<li>{item}</li>" for item in summary["hardware_takeaway"]["pl_core_layers_to_build_now"]
    )
    not_needed_lines = "".join(
        f"<li>{item}</li>" for item in summary["hardware_takeaway"]["layers_not_needed_as_standalone_blocks"]
    )

    return f"""<!doctype html>
<html lang="zh-Hant">
<head>
  <meta charset="utf-8">
  <title>SR TFLite Hardware Summary</title>
  <style>
    body {{
      margin: 0;
      font-family: "Microsoft JhengHei", "Noto Sans TC", Arial, sans-serif;
      line-height: 1.7;
      color: #20242a;
      background: #f6f8fb;
    }}
    .page {{
      max-width: 1100px;
      margin: 0 auto;
      padding: 32px 24px 56px;
    }}
    h1 {{ font-size: 30px; margin: 0 0 8px; }}
    h2 {{
      font-size: 22px;
      margin-top: 28px;
      border-left: 5px solid #2d7dd2;
      padding-left: 12px;
    }}
    p {{ margin: 10px 0; }}
    .note {{
      padding: 14px 16px;
      background: #eef9f0;
      border: 1px solid #b8dfbf;
      border-radius: 8px;
    }}
    code {{
      font-family: Consolas, "Courier New", monospace;
      background: #eef1f5;
      padding: 2px 5px;
      border-radius: 4px;
    }}
    table {{
      width: 100%;
      border-collapse: collapse;
      margin: 12px 0 20px;
      background: white;
    }}
    th, td {{
      border: 1px solid #d8dee8;
      padding: 9px 10px;
      vertical-align: top;
      text-align: left;
    }}
    th {{ background: #e9eef5; }}
    pre {{
      overflow-x: auto;
      background: #18202a;
      color: #eef4fb;
      padding: 16px;
      border-radius: 8px;
      line-height: 1.55;
    }}
  </style>
</head>
<body>
  <main class="page">
    <h1>SR TFLite Hardware Summary</h1>
    <p>這份摘要是給硬體設計閱讀的，不是給 Python 工具直接解析的。</p>
    <p>來源模型：<code>{summary["source_tflite"]}</code></p>

    <h2>1. 目前硬體真正要做哪些 Layer</h2>
    <div class="note">
      <ul>{now_lines}</ul>
    </div>

    <h2>2. 哪些不用做成獨立 Layer</h2>
    <ul>{not_needed_lines}</ul>

    <h2>3. 建議 PL Pipeline</h2>
    <ul>{pipeline_lines}</ul>

    <h2>4. TFLite Operator 到硬體 Block 對照</h2>
    <table>
      <thead>
        <tr>
          <th>Stage</th>
          <th>Name</th>
          <th>TFLite Ops</th>
          <th>Hardware Action</th>
          <th>Where</th>
          <th>Separate PL Layer</th>
          <th>Note</th>
        </tr>
      </thead>
      <tbody>
        {''.join(rows)}
      </tbody>
    </table>

    <h2>5. 直接回答目前模型要做什麼</h2>
    <pre>Input uint8
  -> input quantize / preprocessing
  -> Conv1 3x3 + requant + fused ReLU
  -> Conv3 1x1 + requant
  -> PixelShuffle
  -> output clip (MINIMUM + RELU)
  -> final uint8 output</pre>
  </main>
</body>
</html>
"""


def main():
    root = default_project_root()
    parser = argparse.ArgumentParser(
        description="Extract SR model int8 weights and hardware requantization params."
    )
    parser.add_argument(
        "--tflite",
        default=str(root / "model_lite" / "sr_core" / "tools" / "Bilinear_PP_v5_test_qat.tflite"),
        help="Path to the SR int8 TFLite model.",
    )
    parser.add_argument(
        "--out-dir",
        default=str(root / "model_lite" / "sr_core" / "generated"),
        help="Output directory.",
    )
    args = parser.parse_args()

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    model = TFLiteModel(args.tflite)
    layers = extract_layers(model)
    report = build_report(model, layers)
    hw_summary = build_hw_summary(model, layers)

    json_path = out_dir / "sr_tflite_params.json"
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2, default=to_builtin)

    summary_json_path = out_dir / "sr_tflite_hw_summary.json"
    with open(summary_json_path, "w", encoding="utf-8") as f:
        json.dump(hw_summary, f, indent=2, default=to_builtin)

    summary_html_path = out_dir / "sr_tflite_hw_summary.html"
    write_text(summary_html_path, render_hw_summary_html(hw_summary))

    for layer in layers:
        write_layer_files(out_dir, layer)

    print(f"Wrote: {json_path}")
    print(f"Wrote: {summary_json_path}")
    print(f"Wrote: {summary_html_path}")
    for layer in layers:
        print(
            f"{layer['name']}: weight {layer['weight']['shape']}, "
            f"bias {layer['bias']['shape']}, output zp {layer['requant']['output_zero_point']}"
        )


if __name__ == "__main__":
    main()
