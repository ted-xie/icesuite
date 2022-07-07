# Settings for iCE40-HX8K-CT256
TOP=uart
SRCS=uart.v

bin/uart_tb: uart_tb.v ${SRCS}
	mkdir -p bin
	iverilog $^ -g2005-sv -gno-specify -o $@

uart_tb: bin/uart_tb

test: bin/uart_tb
	$<

ICESUITE_HOME=$(shell git rev-parse --show-toplevel)
include ${ICESUITE_HOME}/boards/hx8k_breakout/hx8k_breakout.mk
