#!/bin/bash


nasm -f elf64 mygrep.s -o mygrep.o
nasm -f elf64 mygrepdep.s -o mygrepdep.o
ld mygrep.o mygrepdep.o -o mygrep