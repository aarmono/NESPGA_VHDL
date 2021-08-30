DASM=./dasm
TESTBINARIES=${patsubst %.tmpl,%.bin,${wildcard *.tmpl}}
MODULES=${patsubst %.tmod,%.py,${wildcard *.tmod}}
export PYTHONPATH=.

all : ${MODULES} ${TESTBINARIES}

clean :
	rm *.bin *.asm *.py *.pyc *.bak dasm

%.bin : %.asm
	${DASM} $< -f3 -o$*.bin -E2
