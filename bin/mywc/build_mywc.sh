#!/bin/bash


nasm -f elf64 mywc.s -o mywc.o
nasm -f elf64 mywcdep.s -o mywcdep.o
ld mywc.o mywcdep.o -o mywc