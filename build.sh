#!/bin/sh
# You need to have nasm and svgalib packages installed
nasm -w-error=label-redef-late -f elf64 -g -F dwarf tetris.asm
export CPATH=/usr/local/include
export LIBRARY_PATH=/usr/local/lib
cc -g -pipe tetris.o -o tetris -lvga -lvgagl -lm
