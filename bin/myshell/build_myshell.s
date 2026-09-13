#!/bin/bash


nasm -f elf64 myshell.s -o myshell.o
nasm -f elf64 ./dep/myshelldep.s -o ./dep/myshelldep.o
nasm -f elf64 ./dep/myshellbif.s  -o ./dep/myshellbif.o

ld   myshell.o \
	./dep/myshelldep.o \
    ./dep/myshellbif.o \
    /home/sarthak/Desktop/asm/bin/dependencies/errorHandling.o \
    /home/sarthak/Desktop/asm/bin/dependencies/mymalloc.o \
   	-o myshell