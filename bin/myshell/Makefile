FFLAG = -f elf64

.PHONY: all final cleaning linking building 

building:
	@echo "Building objects files"
	@nasm $(FFLAG) ./src/myshell.s -o ./src/myshell.o
	@nasm $(FFLAG) ./src/dep/read_input.s -o ./src/dep/read_input.o
	@nasm $(FFLAG) ./src/dep/custom_errors.s -o ./src/dep/custom_errors.o
	@nasm $(FFLAG) ./src/dep/myshelldep.s -o ./src/dep/myshelldep.o
	@nasm $(FFLAG) ./src/dep/myshellbif.s  -o ./src/dep/myshellbif.o
	@nasm $(FFLAG) ./src/dep/env_funcs.s  -o ./src/dep/env_funcs.o
	@nasm $(FFLAG) ./src/dep/history.s -o ./src/dep/history.o
	@nasm $(FFLAG) ./src/dep/proper_print.s -o ./src/dep/proper_print.o
	@nasm $(FFLAG) ./src/dep/parse_input.s -o ./src/dep/parse_input.o
	@nasm $(FFLAG) ./src/dep/process_tokens.s -o ./src/dep/process_tokens.o
	@nasm $(FFLAG) ./src/dep/execute_commands.s -o ./src/dep/execute_commands.o

	@nasm $(FFLAG) ../dependencies/errorHandling.s -o ../dependencies/errorHandling.o 
	@nasm $(FFLAG) ../dependencies/mystring.s -o ../dependencies/mystring.o 
	@nasm $(FFLAG) ../dependencies/dynamicarray.s -o ../dependencies/dynamicarray.o 
	@nasm $(FFLAG) ../dependencies/mymalloc2.s -o ../dependencies/mymalloc2.o 
	@nasm $(FFLAG) ../dependencies/hashset.s -o ../dependencies/hashset.o
	@nasm $(FFLAG) ../dependencies/linkedlist.s -o ../dependencies/linkedlist.o

# 	nasm $(FFLAG) ../dependencies/mymalloc.s -o ../dependencies/mymalloc.o 


linking: building
	@echo "Linking object files"
	@ld  ./src/myshell.o \
    ./src/dep/read_input.o \
    ./src/dep/parse_input.o \
    ./src/dep/process_tokens.o \
    ./src/dep/execute_commands.o \
    ./src/dep/custom_errors.o \
	./src/dep/myshelldep.o \
    ./src/dep/myshellbif.o \
    ./src/dep/env_funcs.o \
    ./src/dep/history.o \
    ./src/dep/proper_print.o \
    ../dependencies/errorHandling.o \
    ../dependencies/mymalloc2.o \
    ../dependencies/mystring.o \
    ../dependencies/dynamicarray.o \
    ../dependencies/hashset.o \
    ../dependencies/linkedlist.o \
   	-o myshell


cleaning: linking
	@echo "Running cleanup"
	@rm ./src/myshell.o \
    ./src/dep/read_input.o \
    ./src/dep/parse_input.o \
    ./src/dep/process_tokens.o \
    ./src/dep/execute_commands.o \
    ./src/dep/custom_errors.o \
    ./src/dep/myshelldep.o \
    ./src/dep/myshellbif.o \
    ./src/dep/env_funcs.o \
    ./src/dep/history.o \
    ./src/dep/proper_print.o \
    ../dependencies/errorHandling.o \
    ../dependencies/mymalloc2.o \
    ../dependencies/mystring.o \
    ../dependencies/dynamicarray.o \
    ../dependencies/hashset.o \
    ../dependencies/linkedlist.o 


final: cleaning
	@echo "Build finished"


all: final