IVL := iverilog

SRC := \
	cpu.v \
	alu.v \
	regfile.v \
	library.v \
	sram-issi.v

#SRC += ../lib/library.v
SRC += testbench.v

EXTRADEPS := ram.txt makerambanks.py

all: testbench 

testbench: $(SRC)
	$(IVL) -o testbench $(SRC)

testbench.vcd: testbench $(EXTRADEPS)
	./makerambanks.py
	./testbench

wave: testbench.vcd
	gtkwave testbench.vcd

clean::
	rm -f *~ testbench testbench.vcd
