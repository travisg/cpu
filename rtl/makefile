BUILD := build
TESTBENCH := $(BUILD)/testbench

SRC := \
	cpu/cpu.v \
	cpu/stage1_fetch.v \
	cpu/stage2_decode.v \
	cpu/stage3_execute.v \
	cpu/stage4_memory.v \
	cpu/stage5_writeback.v \
	cpu/alu.v \
	cpu/regfile.v \
	lib/library.v

#SRC += ../lib/library.v
SRC += testbench.v

#EXTRADEPS := ram.txt makerambanks.py
EXTRADEPS := test2.asm.hex

all: $(TESTBENCH)

$(TESTBENCH): $(SRC) testbench.cpp
	mkdir -p $(dir $@)
	verilator -Wno-fatal --top-module testbench --Mdir $(dir $@) -Icpu --exe testbench.cpp --cc -DSIMULATION -CFLAGS -DTRACE --trace $(SRC)
	make -C $(dir $@) -f Vtestbench.mk

.PHONY: vcd wave

vcd: $(TESTBENCH)
	cd $(BUILD); \
	./Vtestbench

wave: vcd
	gtkwave $(BUILD)/trace.vcd

clean::
	rm -rf $(BUILD)
