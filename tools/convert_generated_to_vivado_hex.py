from pathlib import Path


SOURCE_DIR = Path("model_lite/sr_core/generated")
OUTPUT_DIR = Path("model_lite/sr_core/generated_vivado_hex")


def get_format_info(relative_path):
    name = relative_path.name.lower()

    if name.endswith("m1.mem"):
        return 64, True
    if name.endswith("m0.mem"):
        return 32, True
    if name.endswith("bias.mem"):
        return 32, True
    if name.endswith("acc_int32.mem"):
        return 32, True
    if "uint8" in name:
        return 8, False
    if "int8" in name:
        return 8, True
    if name.endswith("weight.mem"):
        return 8, True

    raise ValueError(f"Unknown width/signedness for {relative_path}")


def decimal_to_hex(value, width):
    mask = (1 << width) - 1
    encoded = value & mask
    hex_digits = (width + 3) // 4
    return f"{encoded:0{hex_digits}X}"


def hex_to_decimal(hex_text, width, signed):
    value = int(hex_text, 16)
    if signed and value >= (1 << (width - 1)):
        value -= 1 << width
    return value


def read_decimal_mem(path):
    values = []
    for line in path.read_text(encoding="ascii").splitlines():
        text = line.strip()
        if text:
            values.append(int(text))
    return values


def write_memh(path, hex_values):
    path.write_text("\n".join(hex_values) + "\n", encoding="ascii")


def write_coe(path, hex_values):
    lines = [
        "memory_initialization_radix=16;",
        "memory_initialization_vector=",
    ]
    for index, value in enumerate(hex_values):
        suffix = ";" if index == len(hex_values) - 1 else ","
        lines.append(value + suffix)
    path.write_text("\n".join(lines) + "\n", encoding="ascii")


def main():
    source_root = SOURCE_DIR.resolve()
    output_root = OUTPUT_DIR.resolve()
    output_root.mkdir(parents=True, exist_ok=True)

    summary = [
        "generated_vivado_hex conversion summary",
        f"source={source_root}",
        f"output={output_root}",
        "",
    ]

    total_files = 0
    total_values = 0
    total_mismatch = 0

    for source_path in sorted(source_root.rglob("*.mem")):
        relative_path = source_path.relative_to(source_root)
        width, signed = get_format_info(relative_path)
        values = read_decimal_mem(source_path)

        hex_values = []
        mismatch = 0
        for value in values:
            hex_text = decimal_to_hex(value, width)
            round_trip = hex_to_decimal(hex_text, width, signed)
            if round_trip != value:
                mismatch += 1
            hex_values.append(hex_text)

        target_dir = output_root / relative_path.parent
        target_dir.mkdir(parents=True, exist_ok=True)

        base_name = relative_path.stem
        write_memh(target_dir / f"{base_name}.memh", hex_values)
        write_coe(target_dir / f"{base_name}.coe", hex_values)

        total_files += 1
        total_values += len(values)
        total_mismatch += mismatch

        summary.append(
            f"file={relative_path.as_posix()} width={width} "
            f"signed={signed} values={len(values)} mismatch={mismatch}"
        )

    summary.extend(
        [
            "",
            f"total files={total_files}",
            f"total values={total_values}",
            f"total mismatch={total_mismatch}",
            "PASS" if total_mismatch == 0 else "FAIL",
        ]
    )

    result_path = output_root / "conversion_verify_result.txt"
    result_path.write_text("\n".join(summary) + "\n", encoding="ascii")

    for line in summary:
        print(line)


if __name__ == "__main__":
    main()
