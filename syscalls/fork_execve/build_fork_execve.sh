#!/bin/bash


nasm -f elf64 fork_execve.s -o fork_execve.o
nasm -f elf64 ./dep/fork_execve_dep.s -o ./dep/fork_execve_dep.o
ld fork_execve.o \
	./dep/fork_execve_dep.o \
	/home/sarthak/Desktop/asm/bin/dependencies/errorHandling.o \
	-o fork_execve