"""
ogc Package
"""

cdef extern void initvideo()
cdef extern void initpad()
cdef extern void initaudio()
cdef extern void initlwp()
cdef extern void initnet()
cdef extern void initwpad()

cdef extern void exit(int)
cdef extern int  fatInitDefault()
cdef extern int net_init()
# TODO Priority:
#   PAD <DONE>
#   Framebuffer video support <Partially Implemented>
#   SDCARD <Wow! That was easy: DONE>
#   WPAD <Partially Implemented>
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
initwpad()
initaudio()
initlwp()
initnet()



# Import all modules
import video
import pad
import wpad
import audio
import lwp
xfbs = None
def Init(console=True, mode=None, numFBs=2, initFat=True):
	global xfbs
	if xfbs != None:
		return xfbs
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
	# Important: you must call this to use pad/wpad
	video.SetPostRetraceCallback(incVICount)
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
	
	


