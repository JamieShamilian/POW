"""
AUDIO Subsystem
"""

cdef extern from "ogc/audio.h":
	void AUDIO_Init(unsigned char*)
	void AUDIO_InitDMA(void*, unsigned int)
	void AUDIO_StartDMA()
	void AUDIO_StopDMA()
	void AUDIO_SetDSPSampleRate(unsigned char)
	unsigned int AUDIO_GetDMABytesLeft()
	unsigned int AUDIO_GetDMALength()
	ctypedef void (*AIDCallback)()
	AIDCallback AUDIO_RegisterDMACallback(AIDCallback)

cdef extern from "malloc.h":
	void* memalign(unsigned int, unsigned int)
	void free( void* )

cdef extern from "Python.h":
	object PyBuffer_FromReadWriteMemory(void*, int)
	int PyObject_AsReadBuffer(object obj, void **buffer, int *buffer_len) except -1
	int PyObject_AsWriteBuffer(object obj, void **buffer, int *buffer_len) except -1
	void Py_INCREF(object o)
	void Py_DECREF(object o)

cdef extern void* memset(void*, int, unsigned int)

AUDIO_Init(NULL)

# State variables
_current_buffer = None
_callback = None
_loop = False

# A small sample of silence
cdef short* silence
silence = <short*>memalign(32, 32)
memset(silence, 0, 32)
# FIXME: Is there any way to free this if this module is garbage collected?

cdef void _cb_func():
	# Allow the audio_buffer to be freed now
	if _current_buffer != None:
		Py_DECREF(_current_buffer)
		_current_buffer = None
	# Let's only let the callback happen once
	AUDIO_RegisterDMACallback(NULL)
	# If we're not looping, send out silence
	if not _loop:
		global silence
		AUDIO_InitDMA(silence, 32)
		AUDIO_StartDMA()
	# Call the user-specified method, if any
	if _callback: _callback()

def Play(audio_buffer, rate=None, loop=False, callback=None):
	"""
	Play audio_buffer through the audio interface
	audio must be stereo, 16-bit, signed samples; aligned to 32B
	you may supply a rate (SAMPLERATE_32KHZ or SAMPLERATE_48KHZ)
	and a callback which is called when the sample is done playing
	This will raise an IOError if a audio transfer is in progress
	  or a ValueError if audio_buffer is invalid or not properly aligned
	"""
	
	# Check that there's not a transfer in progress
	if AUDIO_GetDMABytesLeft() > 0:
		raise IOError
	
	# Increase the reference count so the audio won't be gc'ed
	global _current_buffer
	_current_buffer = audio_buffer
	Py_INCREF(audio_buffer)
	# Get a C array for the samples
	cdef void* csamples
	cdef int clen
	PyObject_AsReadBuffer(audio_buffer, &csamples, &clen)
	
	if csamples == NULL or <long>csamples & 0x1F or clen & 0x1F:
		# ValueError will be raised if the buffer is invalid
		#   or if the audio it represents is not aligned
		raise ValueError
	
	# Set user parameters if given
	if rate != None:
		SetRate(rate)
	
	global _callback
	_callback = callback
	AUDIO_RegisterDMACallback(_cb_func)
	
	global _loop
	_loop = loop
	
	AUDIO_InitDMA(csamples, clen)
	AUDIO_StartDMA()

def Stop():
	# Stop playing the current sample
	AUDIO_StopDMA()

SAMPLERATE_32KHZ = 0
SAMPLERATE_48KHZ = 1

def SetRate(rate):
	# Set the rate of samples (SAMPLERATE_32KHZ or SAMPLERATE_48KHZ)
	AUDIO_SetDSPSampleRate(rate)

def BytesLeft():
	return AUDIO_GetDMABytesLeft()
	
	
