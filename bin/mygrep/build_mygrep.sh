#!/bin/bash


nasm -f elf64 mygrep.s -o mygrep.o
nasm -f elf64 ./dep/mygrepdep.s -o ./dep/mygrepdep.o

    
nasm -f elf64 ../dependencies/errorHandling.s -o ../dependencies/errorHandling.o 
nasm -f elf64 ../dependencies/mymalloc.s -o ../dependencies/mymalloc.o 

ld   mygrep.o \
	./dep/mygrepdep.o \
    ../dependencies/errorHandling.o \
    ../dependencies/mymalloc.o \
   	-o mygrep

rm  ../dependencies/errorHandling.o \
    ../dependencies/mymalloc.o 