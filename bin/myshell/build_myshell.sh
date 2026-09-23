#!/bin/bash

nasm -f elf64 myshell.s -o myshell.o
nasm -f elf64 ./dep/read_input.s -o ./dep/read_input.o
nasm -f elf64 ./dep/custom_errors.s -o ./dep/custom_errors.o
nasm -f elf64 ./dep/myshelldep.s -o ./dep/myshelldep.o
nasm -f elf64 ./dep/myshellbif.s  -o ./dep/myshellbif.o
nasm -f elf64 ./dep/env_funcs.s  -o ./dep/env_funcs.o
nasm -f elf64 ./dep/history.s -o ./dep/history.o
nasm -f elf64 ./dep/proper_print.s -o ./dep/proper_print.o
nasm -f elf64 ./dep/parse_input.s -o ./dep/parse_input.o
nasm -f elf64 ./dep/process_tokens.s -o ./dep/process_tokens.o

# only temporary
#nasm -f elf64 ../dependencies/errorHandling.s -o ../dependencies/errorHandling.o 
nasm -f elf64 ../dependencies/mymalloc.s -o ../dependencies/mymalloc.o 
nasm -f elf64 ../dependencies/mystring.s -o ../dependencies/mystring.o 
nasm -f elf64 ../dependencies/dynamicarray.s -o ../dependencies/dynamicarray.o 


ld   myshell.o \
    ./dep/read_input.o \
    ./dep/parse_input.o \
    ./dep/process_tokens.o \
    ./dep/custom_errors.o \
	./dep/myshelldep.o \
    ./dep/myshellbif.o \
    ./dep/env_funcs.o \
    ./dep/history.o \
    ./dep/proper_print.o \
    ../dependencies/errorHandling.o \
    ../dependencies/mymalloc.o \
    ../dependencies/mystring.o \
    ../dependencies/dynamicarray.o \
   	-o myshell

rm   myshell.o \
    ./dep/read_input.o \
    ./dep/parse_input.o \
    ./dep/process_tokens.o \
    ./dep/custom_errors.o \
    ./dep/myshelldep.o \
    ./dep/myshellbif.o \
    ./dep/env_funcs.o \
    ./dep/history.o \
    ./dep/proper_print.o
