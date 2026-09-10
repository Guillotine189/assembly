#!/bin/bash


nasm -f elf64 mymalloc.s -o mymalloc.o
nasm -f elf64 ./dep/mymallocdep.s -o ./dep/mymallocdep.o
nasm -f elf64 ./dep/errorHandling.s -o ./dep/errorHandling.o
ld mymalloc.o ./dep/mymallocdep.o ./dep/errorHandling.o -o mymalloc