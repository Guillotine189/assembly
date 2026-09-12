#!/bin/bash


nasm -f elf64  pipe.s -o  pipe.o
nasm -f elf64 ./dep/pipedep.s -o ./dep/pipedep.o
ld  pipe.o \
	./dep/pipedep.o \
	/home/sarthak/Desktop/asm/bin/dependencies/errorHandling.o \
	-o  pipe