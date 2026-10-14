FFLAG = -f elf64


all: final

final: building linking cleaning
	@echo "Build finished"



building:
	@echo "Building objects files"
	@nasm $(FFLAG) ./mycat.s -o ./mycat.o
	@nasm $(FFLAG) ./mycatdep.s -o ./mycatdep.o

linking:
	@echo "Linking object files"
	@ld  ./mycat.o ./mycatdep.o -o ./mycat


cleaning:
	@echo "Running cleanup"
	@rm ./mycat.o ./mycatdep.o