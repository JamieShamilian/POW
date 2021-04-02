"""
ogc Package
"""

cdef extern void initvideo()
cdef extern void initpad()
cdef extern void initaudio()
cdef extern void initlwp()

cdef extern void exit(int)
cdef extern int  fatInitDefault()

# TODO Priority:
#   PAD <DONE>
#   Framebuffer video support <Partially Implemented>
#   SDCARD <Wow! That was easy: DONE>
#   WPAD
#   AUDIO <Partially Implemented>
#   GX
#   Threading (LWP) <Almost there>
#   Networking </me Shudders>
#   IOS / ISFS
#   USB Gecko
#   DVD
#   Memory Cards
#   MEM2 / ARAM
#   DSP


# Init all modules
initvideo()
initpad()
initaudio()
initlwp()
# Import all modules
import video
import pad
import audio
import lwp

def Init(console=True, mode=None, numFBs=2, initFat=True):
	# Configure video mode
	video.Configure(mode)
	# Allocate framebuffers
	xfbs = []
	for i in range(numFBs):
		xfbs.append( video.Framebuffer() )
		xfbs[i].clear()
	# Init the console if desired
	if console:
		video.ConsoleInit(xfbs[0])
	# Set the next framebuffer
	video.SetNextFramebuffer(xfbs[0])
	# Important: you must call this to use pad module
	video.SetPostRetraceCallback(pad.SetReadFlag)
	# We don't want VI to black on VI, flush settings
	video.SetBlack(False)
	video.Flush()
	video.WaitVSync()
	# Initialize libfat
	if initFat: fatInitDefault()
	# Return framebuffers
	return xfbs

def Reload():
	exit(0)
	
	


