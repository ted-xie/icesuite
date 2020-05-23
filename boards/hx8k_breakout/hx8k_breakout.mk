# Settings for iCE40-HX8K-CT256

ifeq (${ICESUITE_HOME},)
	ICESUITE_HOME=$(shell git rev-parse --show-toplevel)
endif
CONSTRAINTS=${ICESUITE_HOME}/boards/hx8k_breakout/hx8k_breakout.pcf
NEXTPNR_OPTS=--hx8k --package ct256
ARACHNEPNR_OPTS=-d 8k -P ct256
ICETIME_OPTS=-d hx8k

include ${ICESUITE_HOME}/boards/common.mk
