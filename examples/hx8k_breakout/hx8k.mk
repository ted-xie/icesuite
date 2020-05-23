# Settings for iCE40-HX8K-CT256
CONSTRAINTS=hx8k.pcf
NEXTPNR_OPTS=--hx8k --package ct256
ARACHNEPNR_OPTS=-d 8k -P ct256
ICETIME_OPTS=-d hx8k

BLIF=${TOP}.blif
ASC=${TOP}.asc
BIT=${TOP}.bit
PNR_NET=${TOP}.pnr.v
TIME_NET=${TOP}.timing.v

${BLIF}: ${SRCS}
	yosys -p 'synth_ice40 -top ${TOP} -blif ${BLIF}' ${SRCS}

synth: ${BLIF}

${ASC}: ${BLIF} ${CONSTRAINTS}
	arachne-pnr ${ARACHNEPNR_OPTS} -o ${ASC} -p ${CONSTRAINTS} ${BLIF}

pnr: ${ASC}

${BIT}: ${ASC}
	icepack ${ASC} ${BIT}

bit: ${BIT}

${PNR_NET}: ${ASC}
	icebox_vlog -p ${CONSTRAINTS} ${ASC} > ${PNR_NET}

pnr_netlist: ${PNR_NET}

${TIME_NET}: ${ASC}
	icetime -p ${CONSTRAINTS} ${ICETIME_OPTS} ${ASC} -o ${TIME_NET}

timing_netlist: ${TIME_NET}

# NOTE: Assumes CRAM config mode. Does not work with Flash SPI programming.
program: ${BIT}
	iceprog -S ${BIT}

clean:
	rm -f ${ASC} ${BLIF} ${BIT} ${TIME_NET} ${PNR_NET}
