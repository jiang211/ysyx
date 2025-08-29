TOPNAME = ysyxSoCFull

INC_PATH ?=
NVBOARD_HOME ?= $(HOME)/ysyx-workbench/nvboard

VERILATOR = verilator

#VERILATOR_FLAGS += -O3 --x-assign fast --x-initial fast 
VERILATOR_FLAGS += -O3 --x-assign fast --x-initial fast 
VERILATOR_FLAGS += -Wall
VERILATOR_FLAGS += --cc 
VERILATOR_FLAGS += --MMD
#VERILATOR_FLAGS += --coverage
#VERILATOR_FLAGS += --assert
VERILATOR_FLAGS += --build
#VERILATOR_FLAGS += --lint-only
VERILATOR_FLAGS += --trace-fst
VERILATOR_FLAGS += -I$(YSYXSOC)/perip/uart16550/rtl
VERILATOR_FLAGS += -I$(YSYXSOC)/perip/spi/rtl
VERILATOR_FLAGS += --timescale "1ns/1ns"
VERILATOR_FLAGS += --no-timing
VERILATOR_FLAGS += --top-module $(TOPNAME)
VERILATOR_FLAGS += --Wno-UNUSED
# 取消未驱动信号的报错（仅显示警告） 
VERILATOR_FLAGS += --Wno-UNDRIVEN
VERILATOR_FLAGS += --Wno-ASSIGNDLY
VERILATOR_FLAGS += --Wno-DECLFILENAME
VERILATOR_FLAGS += --Wno-DEFPARAM
VERILATOR_FLAGS += --Wno-PINCONNECTEMPTY
VERILATOR_FLAGS += --Wno-SYNCASYNCNET
VERILATOR_FLAGS += --Wno-WIDTHEXPAND
VERILATOR_FLAGS += --autoflush
#VERILATOR_FLAGS += --debug --gdbbt

YSYXSOC ?= $(HOME)/ysyx-workbench/ysyxSoC  # 默认路径，按需修改
WORK_DIR = $(shell pwd)
BUILD_DIR = $(WORK_DIR)/build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)

default: $(BIN)
$(shell mkdir -p $(BUILD_DIR))
######################################################nvboard####################################
# rules for NVBoard

NXDC_FILES = constr/ysyxSoCFull.nxdc
SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
$(SRC_AUTO_BIND): $(NXDC_FILES)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@





##################################################################################################

ysyxsoc = $(YSYXSOC)
VS_DIR = $(WORK_DIR)/vsrc
VSRCS = $(shell find $(VS_DIR) -name "*.v")
VSRCS += $(shell find $(YSYXSOC)/perip -name "*.v")
VSRCS += $(YSYXSOC)/build/ysyxSoCFull.v

CXXFLAGS += $(shell llvm-config --cxxflags) -fPIE
CS_DIR = $(WORK_DIR)/csrc
CSRCS = $(shell find $(CS_DIR) -name "*.c" -or -name "*.cc" -or -name "*.cpp")
CSRCS += $(SRC_AUTO_BIND)

include $(NVBOARD_HOME)/scripts/nvboard.mk
INC_PATH += $(abspath ./csrc/include)
INC_PATH += $(abspath ./obj_dir)
#INC_PATH += $(NVBOARD_HOME)/include
INCFLAGS = $(addprefix -I, $(INC_PATH))

CXXFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""
CFLAGS += -O2 -MMD -Wall  $(INCFLAGS) -Og -ggdb3 -g

LDFLAGS += $(shell llvm-config --libs) 
LDFLAGS += -O2 -Og -ggdb3 -ldl -pie -lreadline 
VERILATOR_FLAGS += $(addprefix -CFLAGS , $(CFLAGS) $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS))
CXXFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""
CXXFLAGS += -DNVBOARD


VERILATOR_OUTFLAGS += --Mdir $(OBJ_DIR) 

# Along with sim_main.cpp wrapper file, so the build will create an executable instead of only a library
VERILATOR_OUTFLAGS += --exe

# Specify the name for the executable built if using --exe. Default to the --prefix if not specified
VERILATOR_OUTFLAGS += -o $(abspath $(BIN))

#riscv64-unknown-elf-gcc -march=rv32g -mabi=ilp32 -fno-pic -c -O2 char-test.c 

$(BIN): $(VSRCS) $(CSRCS) $(NVBOARD_ARCHIVE)
	@rm -rf $(OBJ_DIR)
	@$(VERILATOR) $(VERILATOR_FLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))
		$(VERILATOR_OUTFLAGS) 


NPC_FLAGS += $(ARGS)
#NPC_FLAGS += -b
NPC_FLAGS +=  --log=$(BUILD_DIR)/npc-log.txt

NPC_FLAGS += --diff=$(NEMU_HOME)/build/riscv32-nemu-interpreter-so

# image file from abstract_machine
#make run IMG=~/ysyx-workbench/am-kernels/tests/cpu-tests/build/add-riscv32e-npc.bin

IMG ?=
NPC_FLAGS += $(IMG)


WAVEFLAGS = gtkwave $(BUILD_DIR)/logs/$(TOPNAME).fst


all : default

wave :  ./build/ysyxSoCFull
	gtkwave *.fst

-include $(NEMU_HOME)/../Makefile

gdb : $(BIN)
	@gdb --args $(BIN) $(NPC_FLAGS) 

run: $(BIN)
	@echo "YSYXSOC = $(YSYXSOC)"
	$(call git_commit, "run npc") # DO NOT REMOVE THIS LINE!!!
	@$(BIN) $(NPC_FLAGS) 2>&1 | tee $(SIM_LOG)
	



PERF_FILE = PERF.md
SIM_LOG = $(BUILD_DIR)/sim.log
TIME_FILE = /home/jx/ysyx-workbench/yosys-sta/result/ysyx_24070003_cpu/ysyx_24070003_cpu.rpt
FACE_FILE = /home/jx/ysyx-workbench/yosys-sta/result/ysyx_24070003_cpu/synth_stat.txt
#  要先在yosys-sta下运行出综合文件，再运行perf.sh脚本
# 初始化性能记录文件（首次运行时创建表头）
init-perf:
	@echo "创建性能记录文件..."
	@echo "| 测试时间 | Commit | 说明 | 周期数 | 指令数 | IPC | 综合频率 | 综合面积 | LSU计数 | IFU计数 | 计算类指令 | 跳转指令 | 加载指令 | 存储指令 | C类指令 | LSU平均 | IFU平均 | 加载平均 | 存储平均 |ICACHE命中率 | ICACHE丢失率 | total_access| access_time| miss_penalty|" > ${PERF_FILE}
	@echo "|----------|--------|------|--------|--------|-----|------|------|---------|---------|------------|----------|----------|----------|--------|---------|---------|----------|----------|----------|----------|----------|----------|----------|" >> ${PERF_FILE}

perf: 
	@echo "记录性能数据..."
	@bash tool/perf.sh $(SIM_LOG) $(PERF_FILE) $(TIME_FILE) $(FACE_FILE)
	@echo "记录已添加到 $(PERF_FILE)"
	@tail -n1 $(PERF_FILE)


clean :
	@rm -rf $(BUILD_DIR)
	@rm -rf $(OBJ_DIR)/*.d
 
	

