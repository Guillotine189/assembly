#!/bin/bash


nasm -f elf64 mmap.s -o mmap.o
nasm -f elf64 ./dep/mmapdep.s -o ./dep/mmapdep.o
nasm -f elf64 ./dep/errorHandling.s -o ./dep/errorHandling.o
ld mmap.o ./dep/mmapdep.o ./dep/errorHandling.o -o mmap