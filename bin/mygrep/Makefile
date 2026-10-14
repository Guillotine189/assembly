FFLAG = -f elf64


all: final

final: building linking cleaning
	@echo "Build finished"


building:
	@echo "Building objects files"
	@nasm $(FFLAG) mygrep.s -o mygrep.o
	@nasm $(FFLAG) ./dep/mygrepdep.s -o ./dep/mygrepdep.o

	@nasm $(FFLAG) ../dependencies/errorHandling.s -o ../dependencies/errorHandling.o 
	@nasm $(FFLAG) ../dependencies/mymalloc.s -o ../dependencies/mymalloc.o 


linking:
	@echo "Linking object files"
	@ld  ./mygrep.o \
		./dep/mygrepdep.o \
    	../dependencies/errorHandling.o \
    	../dependencies/mymalloc.o \
   		-o mygrep


cleaning:
	@echo "Running cleanup"
	@rm mygrep.o \
		./dep/mygrepdep.o \
		../dependencies/errorHandling.o \
    	../dependencies/mymalloc.o 