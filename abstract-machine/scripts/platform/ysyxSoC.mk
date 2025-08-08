AM_SRCS := riscv/ysyxSoC/start.S \
           riscv/ysyxSoC/trm.c \
           riscv/ysyxSoC/ioe.c \
           riscv/ysyxSoC/timer.c \
           riscv/ysyxSoC/input.c \
           riscv/ysyxSoC/cte.c \
           riscv/ysyxSoC/trap.S \
           platform/dummy/vme.c \
           platform/dummy/mpe.c

CFLAGS    += -fdata-sections -ffunction-sections # 让编译器将每个函数和数据段分别放置在独立的节（section）
CFLAGS    += -Os
LDFLAGS   += -T $(AM_HOME)/scripts/ysyxSoclinker.ld \
						 --defsym=_pmem_start=0x30000000 --defsym=_entry_offset=0x0 --defsym=_sram_start=0x0f000000
LDFLAGS   += --gc-sections -e _start #告诉链接器移除未被使用的节
SOCFLAGS  += -b 
CFLAGS += -DMAINARGS=\"$(mainargs)\"
.PHONY: $(AM_HOME)/am/src/riscv/ysyxSoC/trm.c

image: $(IMAGE).elf
	@$(OBJDUMP) -d $(IMAGE).elf > $(IMAGE).txt
	@echo + OBJCOPY "->" $(IMAGE_REL).bin
	@$(OBJCOPY) -S --set-section-flags .bss=alloc,contents -O binary $(IMAGE).elf $(IMAGE).bin

run: image
	$(MAKE) -C $(NPC_HOME) run IMG=$(IMAGE).bin ELF=$(IMAGE).elf ARGS="$(SOCFLAGS)"

gdb: image
	$(MAKE) -C $(NPC_HOME) gdb IMG=$(IMAGE).bin ELF=$(IMAGE).elf
