.section .text.entry
.globl _start

_start:
    # 1. 禁用中断（防止启动时被干扰）
    csrci mstatus, 8

    # 2. 初始化栈指针 sp
    la sp, _stack_top

    # 3. 初始化全局指针 gp
    .option push
    .option norelax
    la gp, __global_pointer$
    .option pop

    # 4. 清理 BSS 段
    la a0, __bss_start
    la a1, __bss_end
    bgeu a0, a1, 2f
1:
    sd zero, 0(a0)
    addi a0, a0, 8
    bltu a0, a1, 1b
2:

    # 5. 调用 C++ 全局构造函数 (init_array)
    la s0, __init_array_start
    la s1, __init_array_end
3:
    bgeu s0, s1, 4f
    ld a0, 0(s0)
    jalr ra, a0
    addi s0, s0, 8
    j 3b
4:

    # 6. 跳转到 main 函数
    # 注意：jal 会自动把下一条指令 (_halt) 的地址存入 ra 寄存器。
    # 当 main() 内部执行 return 0 时，会将 0 存入 a0，并触发 ret (jalr zero, 0(ra))。
    # 这就是所谓的“自然退出”。
    jal ra, main

    # 7. Trap 停机序列 (自然退出的降落点)
_halt:
    # 此时 a0 正好是 main 的返回值。该指令 (rs1=a0) 完美契合 Difftest 的判断标准。
    .word 0x0005006b
    
    # 防御性死循环：万一 CPU 的 Trap 没写对跑飞了，把它困在这里
_dead_loop:
    j _dead_loop