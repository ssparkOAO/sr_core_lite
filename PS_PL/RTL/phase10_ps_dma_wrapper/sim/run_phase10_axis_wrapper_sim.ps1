$ErrorActionPreference = "Stop"

$simDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$srCoreDir = Resolve-Path (Join-Path $simDir "..\..\..")
$cleanProjectDir = Join-Path $srCoreDir "vivado\sr_core_clean_stream_pynqz2"
$cleanRtlDir = Join-Path $cleanProjectDir "src\rtl"
$ipGenDir = Join-Path $cleanProjectDir "sr_core_clean_stream_pynqz2.gen\sources_1\ip"
$phaseDir = Resolve-Path (Join-Path $simDir "..")
$workDir = Join-Path $phaseDir "work_axis_wrapper"

$vivadoBin = "C:\Xilinx\Vivado\2023.1\bin"
$xvlog = Join-Path $vivadoBin "xvlog.bat"
$xelab = Join-Path $vivadoBin "xelab.bat"
$xsim = Join-Path $vivadoBin "xsim.bat"

if (!(Test-Path $workDir)) {
    New-Item -ItemType Directory -Path $workDir | Out-Null
}

Push-Location $workDir
try {
    Copy-Item -Force (Join-Path $cleanProjectDir "conv1_weight_rom.mif") .
    Copy-Item -Force (Join-Path $cleanProjectDir "conv3_weight_rom.mif") .
    Copy-Item -Force (Join-Path $cleanProjectDir "conv1_m0_rom.mif") .
    Copy-Item -Force (Join-Path $cleanProjectDir "conv1_m1_rom.mif") .
    Copy-Item -Force (Join-Path $cleanProjectDir "conv3_m0_rom.mif") .
    Copy-Item -Force (Join-Path $cleanProjectDir "conv3_m1_rom.mif") .

    & $xvlog `
        (Join-Path $ipGenDir "conv1_weight_rom\simulation\blk_mem_gen_v8_4.v") `
        (Join-Path $ipGenDir "conv1_weight_rom\sim\conv1_weight_rom.v") `
        (Join-Path $ipGenDir "conv3_weight_rom\sim\conv3_weight_rom.v") `
        (Join-Path $ipGenDir "conv1_m0_rom\sim\conv1_m0_rom.v") `
        (Join-Path $ipGenDir "conv1_m1_rom\sim\conv1_m1_rom.v") `
        (Join-Path $ipGenDir "conv3_m0_rom\sim\conv3_m0_rom.v") `
        (Join-Path $ipGenDir "conv3_m1_rom\sim\conv3_m1_rom.v") `
        (Join-Path $ipGenDir "output_image_ram\sim\output_image_ram.v") `
        (Join-Path $cleanRtlDir "pixel_shuffle_core.v") `
        (Join-Path $cleanRtlDir "sr_conv1x1_cin8_cout4_flat.v") `
        (Join-Path $cleanRtlDir "sr_conv1x1_cin8_cout4_mac.v") `
        (Join-Path $cleanRtlDir "sr_conv1_3x3_cin1_cout8_flat.v") `
        (Join-Path $cleanRtlDir "sr_conv1_to_conv3_stream_slice.v") `
        (Join-Path $cleanRtlDir "sr_conv3x3_cin1_cout8_mac.v") `
        (Join-Path $cleanRtlDir "sr_ctrl_clean_stream_img.v") `
        (Join-Path $cleanRtlDir "sr_output_pack2x2_uint8.v") `
        (Join-Path $cleanRtlDir "sr_output_stage.v") `
        (Join-Path $cleanRtlDir "sr_pctrl.v") `
        (Join-Path $cleanRtlDir "sr_requantize.v") `
        (Join-Path $cleanRtlDir "sr_top_clean_stream_img.v") `
        (Join-Path $cleanRtlDir "sr_window_3x3_cin1.v") `
        (Join-Path $simDir "..\rtl\sr_core_axis_wrapper.v") `
        (Join-Path $simDir "tb_sr_core_axis_wrapper.v")

    if ($LASTEXITCODE -ne 0) { throw "xvlog failed with exit code $LASTEXITCODE" }

    & $xelab tb_sr_core_axis_wrapper -debug typical -s tb_sr_core_axis_wrapper_snapshot
    if ($LASTEXITCODE -ne 0) { throw "xelab failed with exit code $LASTEXITCODE" }

    "run all`nexit" | Set-Content -Encoding ASCII -Path "phase10_axis_wrapper_xsim.tcl"
    & $xsim tb_sr_core_axis_wrapper_snapshot -tclbatch phase10_axis_wrapper_xsim.tcl -wdb tb_sr_core_axis_wrapper_snapshot.wdb
    if ($LASTEXITCODE -ne 0) { throw "xsim failed with exit code $LASTEXITCODE" }
}
finally {
    Pop-Location
}
