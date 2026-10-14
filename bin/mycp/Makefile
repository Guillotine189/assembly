FFLAG = -f elf64


all: final

final: building linking cleaning
	@echo "Build finished"



building:
	@echo "Building objects files"
	@nasm $(FFLAG) mycp.s -o mycp.o
	@nasm $(FFLAG) mycpdep.s -o mycpdep.o


linking:
	@echo "Linking object files"
	@ld  mycp.o mycpdep.o -o mycp


cleaning:
	@echo "Running cleanup"
	@rm mycp.o mycpdep.o