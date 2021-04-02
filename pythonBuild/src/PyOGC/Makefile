CC=	powerpc-gekko-gcc
CXX=	powerpc-gekko-g++
AS=	powerpc-gekko-as
PYREXC=	pyrexc
GCUBE=	~/tmp/gcube/gcube

CFLAGS=	-g -O2 -Wall $(MACHDEP)
MACHDEP= -DGEKKO -mcpu=750 -meabi -mhard-float 
LDFLAGS= $(MACHDEP) -mrvl --disable-shared

INCL=	-I../Python-2.5.2/Include -I../Python-2.5.2/ -I$(DEVKITPRO)/libogc/gc

LIB =	-L$(DEVKITPRO)/libogc/lib/wii -L../Python-2.5.2 -logc -lm -lpython2.5 -lfat -lm -logc

PYOGCOBJ = ogc/ogc.o ogc/pad.o ogc/audio.o ogc/video.o \
           ogc/lwp.o ogc/net.o ogc/wpad.o ogc/vicount.o
DEMOOBJ = demo.o hello.o

pyogc.o:  $(PYOGCOBJ) 
	powerpc-gekko-ld -r $(PYOGCOBJ) -o pyogc.o 

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


