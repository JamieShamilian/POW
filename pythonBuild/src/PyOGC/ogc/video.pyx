"""
VIDEO Subsystem
"""

cdef extern from "ogc/gx_struct.h":
	ctypedef struct GXRModeObj:
		unsigned int   viTVMode
		unsigned short fbWidth
		unsigned short efbHeight
		unsigned short xfbHeight
		unsigned short viXOrigin
		unsigned short viYOrigin
		unsigned short viWidth
		unsigned short viHeight
		unsigned int   xfbMode
		unsigned char  field_rendering
		unsigned char  aa
		unsigned char  sample_pattern[12][2]
		unsigned char  vfilter[7]

cdef extern from "ogc/video.h":
	void VIDEO_Flush()
	void VIDEO_WaitVSync()
	void VIDEO_SetNextFramebuffer(void*)
	void VIDEO_Init()
	void VIDEO_SetBlack(unsigned char)
	unsigned int VIDEO_GetCurrentTvMode()
	GXRModeObj* VIDEO_GetPreferredMode(GXRModeObj*)
	void VIDEO_Configure(GXRModeObj*)
	void VIDEO_ClearFrameBuffer(GXRModeObj*, void*, unsigned int)
	ctypedef void (*VIRetraceCallback)(unsigned int retraceCnt)
	VIRetraceCallback VIDEO_SetPostRetraceCallback(VIRetraceCallback)

cdef extern from "ogc/consol.h":
	void console_init(void*, int, int, int, int, int)

cdef extern from "Python.h":
	object PyBuffer_FromReadWriteMemory(void*, int)
	int PyObject_AsReadBuffer(object obj, void **buffer, int *buffer_len) except -1
	int PyObject_AsWriteBuffer(object obj, void **buffer, int *buffer_len) except -1

VIDEO_Init()

VI_NTSC      = 0
VI_PAL       = 1
VI_MPAL      = 2
VI_DEBUG     = 3
VI_DEBUG_PAL = 4
VI_EURGB60   = 5

COLOR_BLACK      = 0x00800080
COLOR_MAROON     = 0x266A26C0
COLOR_GREEN      = 0x4B554B4A
COLOR_OLIVE      = 0x7140718A
COLOR_NAVY       = 0x0EC00E75
COLOR_PURPLE     = 0x34AA34B5
COLOR_TEAL       = 0x59955940
COLOR_GRAY       = 0x80808080
COLOR_SILVER     = 0xC080C080
COLOR_RED        = 0x4C544CFF
COLOR_LIME       = 0x952B9515
COLOR_YELLOW     = 0xE100E194
COLOR_BLUE       = 0x1DFF1D6B
COLOR_FUCHSIA    = 0x69D469EA
COLOR_AQUA       = 0xB2ABB200
COLOR_WHITE      = 0xFF80FF80
COLOR_MONEYGREEN = 0xD076D074
COLOR_SKYBLUE    = 0xC399C36A
COLOR_CREAM      = 0xFA79FA82
COLOR_MEDGRAY    = 0xA082A07F

def Flush():
	VIDEO_Flush()

def WaitVSync():
	VIDEO_WaitVSync()

def SetNextFramebuffer(xfb):
	# Next frame, use the Framebuffer object xfb
	# FIXME: I wish I didn't have to do this
	buf = xfb.get_buffer()
	cdef void* xfbp
	cdef int xfblen
	PyObject_AsReadBuffer(buf, &xfbp, &xfblen)
	
	VIDEO_SetNextFramebuffer(xfbp)

def SetBlack(blackOnVI):
	if blackOnVI: VIDEO_SetBlack(1)
	else: VIDEO_SetBlack(0)

cdef void _post_retrace_cb(unsigned int count):
	if _postRetraceCB:
		_postRetraceCB()

_postRetraceCB = None
def SetPostRetraceCallback(callback=None):
	if not callback:
		VIDEO_SetPostRetraceCallback(NULL)
	else:
		global _postRetraceCB
		_postRetraceCB = callback
		VIDEO_SetPostRetraceCallback(_post_retrace_cb)

cdef GXRModeObj* _mode
_mode = NULL
def Configure(mode=None):
	if mode:
		# TODO: Allow the user to specify a mode string
		raise NotImplementedError
	
	global _mode
	_mode = VIDEO_GetPreferredMode(NULL)
	VIDEO_Configure(_mode)

def ConsoleInit(xfb, xstart=20, ystart=64):
	# FIXME: I wish I didn't have to do this
	buf = xfb.get_buffer()
	cdef void* xfbp
	cdef int xfblen
	PyObject_AsReadBuffer(buf, &xfbp, &xfblen)
	
	console_init(xfbp, xstart, ystart, _mode.fbWidth, _mode.xfbHeight, 2*_mode.fbWidth)

cdef extern void* SYS_AllocateFramebuffer(GXRModeObj*)
cdef class Framebuffer:
	"""
	Class which represent an external framebuffer
	You must configure the video mode before instantiating a framebuffer
	  SystemError will be raised if you fail to do so
	"""
	
	cdef void* xfb
	cdef int buflen
	
	def __cinit__(self):
		if _mode == NULL:
			raise SystemError
		self.xfb = SYS_AllocateFramebuffer(_mode)
		if self.xfb == NULL:
			raise MemoryError
		# xfb = MEM_K0_TO_K1(xfb)
		self.xfb = self.xfb + 0xC0000000 - 0x80000000
		# length (B) = 2 B/pixel * width * height
		self.buflen = 2 * _mode.fbWidth * _mode.xfbHeight
	
	def __dealloc__(self):
		# TODO: Can I actually free a framebuffer?
		pass
	
	def get_buffer(self):
		# This returns a new reference; I shouldn't adjust the ref count right?
		return PyBuffer_FromReadWriteMemory(self.xfb, self.buflen)
	
	def clear(self, color=COLOR_BLACK):
		# Clears the framebuffer with color (default: black)
		VIDEO_ClearFrameBuffer(_mode, self.xfb, color)
	
	# TODO: get_pixel and set_pixel allowing RGB?
		
		

