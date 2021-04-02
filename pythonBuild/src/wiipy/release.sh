#!/bin/sh

rm -rf wiipy_$1
mkdir -p wiipy_$1/apps/wiipy
mkdir -p wiipy_$1/wiipy
cp -v boot.elf meta.xml icon.png wiipy_$1/apps/wiipy
cp -v README.txt examples/run.py wiipy_$1/wiipy
zip -r wiipy_$1.zip wiipy_$1