# gekko no longer supported, using eabi
export PATH=$DEVKITPPC/bin:$PATH
#export CC=powerpc-gekko-gcc
#export CXX=powerpc-gekko-g++
export CC="powerpc-eabi-gcc"
export CXX="powerpc-eabi-g++"
export MACHDEP='-DGEKKO -mrvl -mcpu=750 -meabi -mhard-float'
export CFLAGS="-I/opt/devkitpro/libogc/include -I/opt/devkitpro/libogc/gc $MACHDEP"
export LDFLAGS="../PyOGC/pyogc.o -L/opt/devkitpro/libogc/lib/wii -lz -lfat -lwiiuse -lbte -logc -lm $MACHDEP"
