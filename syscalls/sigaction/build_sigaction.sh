#!/bin/bash


nasm -f elf64  sigaction.s -o  sigaction.o
nasm -f elf64 ./dep/sigactiondep.s -o ./dep/sigactiondep.o
ld  sigaction.o \
	./dep/sigactiondep.o \
	/home/sarthak/Desktop/asm/bin/dependencies/errorHandling.o \
	-o  sigaction