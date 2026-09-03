#!/bin/bash


nasm -f elf64 mycp.s -o mycp.o
nasm -f elf64 mycpdep.s -o mycpdep.o
ld mycp.o mycpdep.o -o mycp