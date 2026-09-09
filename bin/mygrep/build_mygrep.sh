#!/bin/bash


nasm -f elf64 mygrep.s -o mygrep.o
nasm -f elf64 ./dep/mygrepdep.s -o ./dep/mygrepdep.o
nasm -f elf64 ./dep/errorHandling.s -o ./dep/errorHandling.o
ld mygrep.o ./dep/mygrepdep.o ./dep/errorHandling.o -o mygrep