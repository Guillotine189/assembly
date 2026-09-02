#!/bin/bash

nasm -f elf64 mycat.s -o mycat.o
nasm -f elf64 mycatdep.s -o mycatdep.o
ld mycat.o mycatdep.o -o mycat