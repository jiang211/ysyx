ENTRY(_start)
PHDRS { text PT_LOAD; data PT_LOAD; } 

MEMORY {
  mrom : ORIGIN = 0x20000000, LENGTH = 4K
  sram : ORIGIN = 0x0f000000, LENGTH = 8K
  flash : ORIGIN = 0x30000000, LENGTH = 4M
  psram : ORIGIN = 0x80000000, LENGTH = 4M
}

SECTIONS {
  /* _pmem_start and _entry_offset are defined in LDFLAGS */
  . = ORIGIN(flash);
  .text : {
    _stext = .;
    *(entry)
    *(.text*)
  } > flash AT> flash : text
  etext = .;
  _etext = .;
  .rodata : {
    _srodata = .;
    *(.rodata*)
    *(.srodata*)
    _erodata = .;
  } > flash AT> flash
  _data_lma_start = LOADADDR(.rodata) + SIZEOF(.rodata);
  . = ORIGIN(psram);
  .data : {
    _sdata = .;      /* SRAM中数据起始地址 (VMA) */
    *(.data*)
    *(.sdata*)
    _edata = .;      /* SRAM中数据结束地址 (VMA) */
  } > psram AT> flash : data
  _sidata = _data_lma_start; /* flash中初始数据地址 (LMA) */
  edata = .;
  _data = .;
  .bss : {
	_bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
  } > psram AT> flash
  _stack_top = ALIGN(0x10);
  . = _stack_top + 0x800;
  _stack_pointer = .;
  end = .;
  _end = .;
  _heap_start = ALIGN(0x10);
  _heap_end = _heap_start + 0x400;
}
