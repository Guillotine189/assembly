FFLAG = -f elf64


all: final

final: building linking cleaning
	@echo "Build finished"


building:
	@echo "Building objects files"
	@nasm $(FFLAG) mywc.s -o mywc.o
	@nasm $(FFLAG) mywcdep.s -o mywcdep.o

linking:
	@echo "Linking object files"
	@ld  mywc.o mywcdep.o -o mywc

cleaning:
	@echo "Running cleanup"
	@rm mywc.o mywcdep.o