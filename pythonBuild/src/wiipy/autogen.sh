#!/bin/sh
#grr.. can't make a makefile as freeze.py will overwrite it..
. ../source_me.sh
make -C ../PyOGC/ || exit
python ../Python-2.5.2/Tools/freeze/freeze.py -p ../Python-2.5.2 wiipy.py
cat config.c |perl -pe 's/extern void initsignal\(void\);\n/extern void initsignal\(void\);\nextern void initogc\(void\);\n/; s/{"signal", initsignal},/{"signal", initsignal},{"ogc", initogc},/' >configogc.c
mv configogc.c config.c
make -e
mv wiipy boot.elf
