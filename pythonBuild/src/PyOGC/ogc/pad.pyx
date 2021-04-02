"""
PAD Subsystem
"""

cdef extern from "ogc/pad.h":
	ctypedef struct PADStatus:
		unsigned short button
		signed   char  stickX
		signed   char  stickY
		signed   char  substickX
		signed   char  substickY
		unsigned char  triggerL
		unsigned char  triggerR
		unsigned char  analogA
		unsigned char  analogB
		signed   char  err
	
	unsigned int PAD_Read(PADStatus*)
	unsigned int PAD_Init()
	unsigned int PAD_ControlMotor(int pad, unsigned int cmd)

BUTTON_LEFT  =	0x0001
BUTTON_RIGHT =	0x0002
BUTTON_DOWN  =	0x0004
BUTTON_UP    =	0x0008
TRIGGER_Z    =	0x0010
TRIGGER_R    =	0x0020
TRIGGER_L    =	0x0040
BUTTON_A     =	0x0100
BUTTON_B     =	0x0200
BUTTON_X     =	0x0400
BUTTON_Y     =	0x0800
BUTTON_MENU  =	0x1000
BUTTON_START =	0x1000

buttons = ['Left', 'Right', 'Down', 'Up', 'Start',
		   'A', 'B', 'X', 'Y', 'Z', 'L', 'R']

ERR_NONE          =	 0
ERR_NO_CONTROLLER =	-1
ERR_NOT_READY     =	-2
ERR_TRANSFER      =	-3

# Call PAD_Init whenever this module is inited
PAD_Init()

cdef PADStatus pads[4]
cdef extern int _VICount
cdef int _myVICount, _lastUpdate
_myVICount = -1
_lastUpdate = 0

class PAD:
	"""
	PAD class, let you get info from, and control a specific GC controller
	Initialize the object with the pad number
	Button/Stick states can be accessed by padObj['A'] or padObj['LStick']
	"""
	def __init__(self, padNum):
		self.padNum = padNum
		self.lastUpdate = -1
	def __getitem__(self, b):
		global _VICount, _myVICount, _lastUpdate, pads
		if _myVICount != _VICount:
			PAD_Read(pads)
			_myVICount = _VICount
			_lastUpdate = _lastUpdate + 1
		
		if self.lastUpdate != _lastUpdate:
			self._update()
			self.lastUpdate = _lastUpdate
		
		return self._dict[b]
	
	def _update(self):
		# Called to update the pad state
		global pads
		cdef PADStatus pad
		pad = pads[self.padNum]
		self._dict = { 'A'      : pad.button & BUTTON_A,
					   'B'      : pad.button & BUTTON_B,
					   'X'      : pad.button & BUTTON_X,
					   'Y'      : pad.button & BUTTON_Y,
					   'Z'      : pad.button & TRIGGER_Z,
					   'Start'  : pad.button & BUTTON_START,
					   'Up'     : pad.button & BUTTON_UP,
					   'Down'   : pad.button & BUTTON_DOWN,
					   'Left'   : pad.button & BUTTON_LEFT,
					   'Right'  : pad.button & BUTTON_RIGHT,
					   'L'      : pad.button & TRIGGER_L,
					   'R'      : pad.button & TRIGGER_R,
					   'AnalogL': pad.triggerL,
					   'AnalogR': pad.triggerR,
					   'AnalogA': pad.analogA,
					   'AnalogB': pad.analogB,
					   'LStick' : ( pad.stickX, pad.stickY ),
					   'RStick' : ( pad.substickX, pad.substickY ),
					   'Error'  : pad.err }
		
	
	def rumble_start(self):
		PAD_ControlMotor(self.padNum, 1)
	def rumble_stop(self):
		PAD_ControlMotor(self.padNum, 0)
	def rumble_stop_hard(self):
		PAD_ControlMotor(self.padNum, 2)

