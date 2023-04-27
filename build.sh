#!/bin/bash

rgbasm -L -o $1.o $1.asm
#rgbasm -h -L -o $1.o $1.asm #disables optimizations
rgblink -o $1.gb $1.o
rgbfix -v -p 0xFF $1.gb
rm $1.o
