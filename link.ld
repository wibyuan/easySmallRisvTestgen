OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
  /* 这里的 ORIGIN 必须和你的 CPU 设计一致 */
  RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 128K
}

/* 定义堆栈大小 */
STACK_SIZE = 32K;

SECTIONS
{
  /* 入口代码必须放在最前面 */
  .text : {
    __text_start = .;
    *(.text.entry)
    *(.text .text.*)
    __text_end = .;
  } > RAM

  .rodata : {
    . = ALIGN(8);
    *(.rodata .rodata.*)
    *(.srodata .srodata.*)
  } > RAM

  .data : {
    . = ALIGN(8);
    __global_pointer$ = . + 0x800;
    *(.data .data.*)
    *(.sdata .sdata.*)
  } > RAM

  /* C++ 静态构造函数列表 */
  .init_array : {
    . = ALIGN(8);
    __init_array_start = .;
    KEEP(*(SORT_BY_INIT_PRIORITY(.init_array.*) SORT_BY_INIT_PRIORITY(.ctors.*)))
    KEEP(*(.init_array .ctors))
    __init_array_end = .;
  } > RAM

  /* 未初始化数据段 */
  .bss : {
    . = ALIGN(8);
    __bss_start = .;
    *(.bss .bss.*)
    *(.sbss .sbss.*)
    *(COMMON)
    . = ALIGN(8);
    __bss_end = .;
  } > RAM

  /* 堆栈段：放在 RAM 的顶部 */
  .stack (NOLOAD) : {
    . = ALIGN(16);
    _stack_bottom = .;
    . = . + STACK_SIZE;
    _stack_top = .;
  } > RAM

  /* 弃用段 */
  /DISCARD/ : {
    *(.comment)
    *(.eh_frame)
    *(.note.gnu.build-id)
  }
}