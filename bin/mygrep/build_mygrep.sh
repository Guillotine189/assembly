#!/bin/bash


nasm -f elf64 mygrep.s -o mygrep.o
nasm -f elf64 ./dep/mygrepdep.s -o ./dep/mygrepdep.o


ld   mygrep.o \
	./dep/mygrepdep.o \
    /home/sarthak/Desktop/asm/bin/dependencies/errorHandling.o \
    /home/sarthak/Desktop/asm/bin/dependencies/mymalloc.o \
   	-o mygrep