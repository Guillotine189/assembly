#!/bin/bash

file_name=$1

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <filename>"
    exit 1
fi


if [[ "$file_name" != *.s ]]; then
    echo "Enter only .s files"
    exit 1
fi

file_name="${file_name::-2}"

nasm -f elf64 -g -F dwarf -o $file_name.o $file_name.s
ld -o $file_name $file_name.o
rm $file_name.o
