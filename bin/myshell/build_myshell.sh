#!/bin/bash

nasm -f elf64 myshell.s -o myshell.o
nasm -f elf64 ./dep/read_input.s -o ./dep/read_input.o
nasm -f elf64 ./dep/custom_errors.s -o ./dep/custom_errors.o
nasm -f elf64 ./dep/myshelldep.s -o ./dep/myshelldep.o
nasm -f elf64 ./dep/myshellbif.s  -o ./dep/myshellbif.o
nasm -f elf64 ./dep/path_command.s  -o ./dep/path_command.o
nasm -f elf64 ./dep/history.s -o ./dep/history.o
nasm -f elf64 ./dep/proper_print.s -o ./dep/proper_print.o
nasm -f elf64 ./dep/parse_input.s -o ./dep/parse_input.o

ld   myshell.o \
    ./dep/read_input.o \
    ./dep/parse_input.o \
    ./dep/custom_errors.o \
	./dep/myshelldep.o \
    ./dep/myshellbif.o \
    ./dep/path_command.o \
    ./dep/history.o \
    ./dep/proper_print.o \
    ../dependencies/errorHandling.o \
    ../dependencies/mymalloc.o \
    ../dependencies/mystring.o \
   	-o myshell

rm   myshell.o \
    ./dep/read_input.o \
    ./dep/parse_input.o \
    ./dep/custom_errors.o \
    ./dep/myshelldep.o \
    ./dep/myshellbif.o \
    ./dep/path_command.o \
    ./dep/history.o \
    ./dep/proper_print.o
