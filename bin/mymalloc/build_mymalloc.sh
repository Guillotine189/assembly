#!/bin/bash


nasm -f elf64 mymalloc.s -o mymalloc.o
ld mymalloc.o ./dep/mymallocdep.o ./dep/errorHandling.o -o mymalloc