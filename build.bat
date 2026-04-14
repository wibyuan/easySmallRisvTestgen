@echo off
setlocal

:: =========================================
:: 1. 解析参数配置
:: =========================================
set TARGET=%~1
set SRC=%~1.cc

:: 如果没有传入参数，则使用默认的 testicg 和 test.cc
if "%TARGET%"=="" (
    set TARGET=testicg
    set SRC=test.cc
)

echo =========================================
echo   Building RISC-V Bare-metal Test (RV64IM)
echo   Source: %SRC% -^> Output: %TARGET%.*
echo =========================================

:: 检查源文件是否存在
if not exist "%SRC%" (
    echo [ERROR] Source file "%SRC%" not found!
    goto :eof
)

:: =========================================
:: 2. 设置编译参数
:: =========================================
set CROSS=riscv64-unknown-elf-
set COMMON_FLAGS=-mabi=lp64 -mcmodel=medany -ffreestanding -fno-builtin -fno-stack-protector -fno-pic -fno-pie -fno-unwind-tables -fno-asynchronous-unwind-tables -O2
set CXXFLAGS=%COMMON_FLAGS% -Wall -Wextra -fno-exceptions -fno-rtti -fno-threadsafe-statics -fno-use-cxa-atexit

:: =========================================
:: 3. 执行编译与转换流程
:: =========================================
echo [1/6] Compiling start.S ...
%CROSS%gcc %COMMON_FLAGS% -march=rv64im -c start.S -o start.rv64im.o
if %errorlevel% neq 0 goto :error

echo [2/6] Compiling %SRC% ...
%CROSS%g++ %CXXFLAGS% -march=rv64im -c %SRC% -o %TARGET%.rv64im.o
if %errorlevel% neq 0 goto :error

echo [3/6] Linking to ELF ...
%CROSS%g++ %CXXFLAGS% -march=rv64im -nostdlib -nostartfiles -no-pie -T link.ld -Wl,--build-id=none start.rv64im.o %TARGET%.rv64im.o -lgcc -o %TARGET%.elf
if %errorlevel% neq 0 goto :error

echo [4/6] Extracting pure binary (.bin) ...
%CROSS%objcopy -O binary %TARGET%.elf %TARGET%.bin
if %errorlevel% neq 0 goto :error

echo [5/6] Generating disassembly (.S) ...
%CROSS%objdump -d %TARGET%.elf > %TARGET%.S
if %errorlevel% neq 0 goto :error

echo [6/6] Generating Vivado COE format (.coe) ...
:: 使用 PowerShell 将二进制按 64 位 (8 字节) 组合，并严格匹配 Vivado 格式要求
powershell -NoProfile -ExecutionPolicy Bypass -Command "$b=[IO.File]::ReadAllBytes('%TARGET%.bin'); $p=(8-$b.Length%%8)%%8; if($p){$b+=New-Object byte[] $p}; $o='memory_initialization_radix = 16;'+[char]10+'memory_initialization_vector ='+[char]10; for($i=0;$i-lt$b.Length;$i+=8){ $h='{0:x16}' -f [BitConverter]::ToUInt64($b,$i); $o+=$h; if($i -lt $b.Length-8){$o+=[char]10}else{$o+=';'+[char]10} }; [IO.File]::WriteAllText('%TARGET%.coe',$o)"
if %errorlevel% neq 0 goto :error

echo =========================================
echo   SUCCESS! 
echo   Generated: %TARGET%.bin, %TARGET%.S, %TARGET%.coe
echo =========================================
goto :eof

:error
echo =========================================
echo   FAILED! Please check the error messages above.
echo =========================================