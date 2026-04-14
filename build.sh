#!/bin/bash

# =========================================
# easySmallRisvTestgen - macOS/Linux Build Script
# =========================================

# 1. 解析参数配置
TARGET=${1:-testicg}
SRC="${TARGET}.cc"

echo "========================================="
echo "  Building RISC-V Bare-metal Test (RV64IM)"
echo "  Source: $SRC -> Output: $TARGET.*"
echo "========================================="

if [ ! -f "$SRC" ]; then
    echo "[ERROR] Source file '$SRC' not found!"
    exit 1
fi

# 2. 工具链自动嗅探 (兼容 Homebrew 和 SiFive 官方包)
if command -v riscv64-unknown-elf-gcc >/dev/null 2>&1; then
    CROSS="riscv64-unknown-elf-"
elif command -v riscv64-elf-gcc >/dev/null 2>&1; then
    CROSS="riscv64-elf-"
else
    echo "[ERROR] RISC-V toolchain not found! Please install it via Homebrew:"
    echo "        brew install riscv64-elf-gcc"
    exit 1
fi

COMMON_FLAGS="-mabi=lp64 -mcmodel=medany -ffreestanding -fno-builtin -fno-stack-protector -fno-pic -fno-pie -fno-unwind-tables -fno-asynchronous-unwind-tables -O2"
CXXFLAGS="$COMMON_FLAGS -Wall -Wextra -fno-exceptions -fno-rtti -fno-threadsafe-statics -fno-use-cxa-atexit"

# 3. 执行编译与转换流程
echo "[1/6] Compiling start.S ..."
${CROSS}gcc $COMMON_FLAGS -march=rv64im -c start.S -o start.rv64im.o || exit 1

echo "[2/6] Compiling $SRC ..."
${CROSS}g++ $CXXFLAGS -march=rv64im -c "$SRC" -o "${TARGET}.rv64im.o" || exit 1

echo "[3/6] Linking to ELF ..."
${CROSS}g++ $CXXFLAGS -march=rv64im -nostdlib -nostartfiles -no-pie -T link.ld -Wl,--build-id=none start.rv64im.o "${TARGET}.rv64im.o" -lgcc -o "${TARGET}.elf" || exit 1

echo "[4/6] Extracting pure binary (.bin) ..."
${CROSS}objcopy -O binary "${TARGET}.elf" "${TARGET}.bin" || exit 1

echo "[5/6] Generating disassembly (.S) ..."
${CROSS}objdump -d "${TARGET}.elf" > "${TARGET}.S" || exit 1

echo "[6/6] Generating Vivado COE format (.coe) ..."
# 使用 Mac 自带的 Python3 进行 64-bit 严格对齐与端序转换
python3 -c "
import sys
try:
    b = open('${TARGET}.bin', 'rb').read()
    p = (8 - len(b) % 8) % 8
    if p: b += b'\x00' * p
    out = 'memory_initialization_radix = 16;\nmemory_initialization_vector =\n'
    words = [f'{int.from_bytes(b[i:i+8], \"little\"):016x}' for i in range(0, len(b), 8)]
    out += ',\n'.join(words) + ';\n'
    open('${TARGET}.coe', 'w').write(out)
except Exception as e:
    print(f'  - Script error: {e}')
    sys.exit(1)
" || exit 1

echo "========================================="
echo "  SUCCESS!"
echo "  Generated: ${TARGET}.bin, ${TARGET}.S, ${TARGET}.coe"
echo "========================================="