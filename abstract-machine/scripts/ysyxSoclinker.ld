ENTRY(_start)
PHDRS { text PT_LOAD; data PT_LOAD; } 

MEMORY {
  mrom : ORIGIN = 0x20000000, LENGTH = 4K
  sram : ORIGIN = 0x0f000000, LENGTH = 8K
  flash : ORIGIN = 0x30000000, LENGTH = 260000K
}

SECTIONS {
  /* _pmem_start and _entry_offset are defined in LDFLAGS */
  . = ORIGIN(flash);
  .text : {
    *(entry)
    *(.text*)
  } > flash AT> flash : text
  etext = .;
  _etext = .;
  .rodata : {
    .srodata = .;
    *(.rodata*)
    *(.srodata*)
    .erodata = .;
  } > flash AT> flash
  _data_lma_start = LOADADDR(.rodata) + SIZEOF(.rodata);
  . = ORIGIN(sram);
  .data : {
    _sdata = .;      /* SRAM中数据起始地址 (VMA) */
    *(.data*)
    *(.sdata*)
    _edata = .;      /* SRAM中数据结束地址 (VMA) */
  } > sram AT> flash : data
  _sidata = _data_lma_start; /* flash中初始数据地址 (LMA) */
  edata = .;
  _data = .;
  .bss : {
	_bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
  } > sram AT> flash
  _stack_top = ALIGN(0x10);
  . = _stack_top + 0x800;
  _stack_pointer = .;
  end = .;
  _end = .;
  _heap_start = ALIGN(0x10);
  _heap_end = _heap_start + 0x400;
}
