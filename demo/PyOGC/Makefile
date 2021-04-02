CC=	powerpc-gekko-gcc
CXX=	powerpc-gekko-g++
AS=	powerpc-gekko-as
PYREXC=	pyrexc
GCUBE=	~/tmp/gcube/gcube

CFLAGS=	-g -O2 -Wall $(MACHDEP)
MACHDEP= -DGEKKO -mcpu=750 -meabi -mhard-float 
LDFLAGS= $(MACHDEP) -mrvl --disable-shared

DEVKITPRO= /home/mike/tmp/devkitPro
INCL=	-I$(DEVKITPRO)/local/include

LIB =	-L$(DEVKITPRO)/local/lib -logc -lm -lpython2.5 -lfat -lm -logc

PYOGCOBJ = ogc/ogc.o ogc/pad.o ogc/audio.o ogc/video.o \
           ogc/lwp.o
DEMOOBJ = demo.o hello.o

all:	demo.elf
	powerpc-gekko-objcopy -O binary demo.elf demo.dol
	
demo.elf: $(DEMOOBJ) $(PYOGCOBJ)
	$(CC) -o $@ $(LDFLAGS) $^ $(LIB)

%.c:	%.pyx
	$(PYREXC) -o $@ $<

%.o:	%.c
	$(CC) -c $(INCL) $(CFLAGS) -o $@ $<

%.o:	%.cpp
	$(CXX) -c $(CXXFLAGS) -o $@ $<

clean:
	rm $(PYOGCOBJ) $(DEMOOBJ) demo.elf demo.dol

test:	demo.elf
	$(GCUBE) $<


