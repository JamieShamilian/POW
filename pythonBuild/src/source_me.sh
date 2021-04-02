export PATH=$DEVKITPPC/bin:$PATH
export CC=powerpc-gekko-gcc
export CXX=powerpc-gekko-g++
export MACHDEP='-DGEKKO -mrvl -mcpu=750 -meabi -mhard-float'
export CFLAGS="-I/datas/wiidev/libogc/include -I/datas/wiidev/libogc/gc $MACHDEP"
export LDFLAGS="../PyOGC/pyogc.o -L/datas/wiidev/devkitPPC/libogc/lib/wii -lz -lfat -lwiiuse -lbte -logc -lm $MACHDEP"
