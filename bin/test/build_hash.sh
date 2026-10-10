#!/bin/bash


nasm -f elf64 ../dependencies/hashset.s -o ../dependencies/hashset.o
nasm -f elf64 ../dependencies/linkedlist.s -o ../dependencies/linkedlist.o
nasm -f elf64 hashtest.s -o hashtest.o

ld  ../dependencies/hashset.o \
	../dependencies/linkedlist.o \
    ../dependencies/mymalloc2.o \
    ../dependencies/mystring.o \
	hashtest.o \
	-o hash
