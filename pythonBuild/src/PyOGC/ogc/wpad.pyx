"""
WPAD Subsystem
"""

cdef extern from "wiiuse/wpad.h":
    ctypedef struct ir_dot_t:
        pass
    ctypedef struct ir_t:
        ir_dot_t      dot[4]
        unsigned char num_dots
        int aspect
        int pos
        unsigned int vres[2]
        int          offset[2]
        int state
        int ax
        int ay
        int x
        int y
        float distance
        float z
    
    ctypedef struct vec3b_t:
        unsigned char x, y, z
    ctypedef struct orient_t:
        float roll, pitch, yaw
        float a_roll, a_pitch
    ctypedef struct gforce_t:
        float x, y, z
    ctypedef struct joystick_t:
        float ang, mag
    
    ctypedef struct nunchuk_t:
        joystick_t js
        orient_t   orient
        gforce_t   gforce
    
    ctypedef struct expansion_t:
        int type
        
        nunchuk_t nunchuk
        # TODO: Other expansions
        
    ctypedef struct WPADData:
        unsigned short err
        unsigned short btns_d
        unsigned short btns_h
        unsigned short btns_r
        unsigned short btns_l
        ir_t        ir
        vec3b_t     accel
        orient_t    orient
        gforce_t    gforce
        expansion_t exp
    
    void WPAD_Init()
    void WPAD_Shutdown()
    void WPAD_Disconnect(int chan)
    void WPAD_ReadEvent(int chan, WPADData*)
    void WPAD_SetDataFormat(int chan, int fmt)
    # TODO: More prototypes as I need them

cdef extern double sin(double)
cdef extern double cos(double)

BUTTON_2     = 0x0001
BUTTON_1     = 0x0002
BUTTON_B     = 0x0004
BUTTON_A     = 0x0008
BUTTON_MINUS = 0x0010
BUTTON_HOME  = 0x0080
BUTTON_LEFT  = 0x0100
BUTTON_RIGHT = 0x0200
BUTTON_DOWN  = 0x0400
BUTTON_UP    = 0x0800
BUTTON_PLUS  = 0x1000

buttons = ['2', '1', 'B', 'A', '-', '+', 'Home',
           'Left', 'Right', 'Down', 'Up']

NUNCHUK_BUTTON_Z = 0x1 << 16
NUNCHUK_BUTTON_C = 0x2 << 16

FMT_CORE        = 0
FMT_CORE_ACC    = 1
FMT_CORE_ACC_IR = 2

ERR_NONE          =  0
ERR_NO_CONTROLLER = -1
ERR_NOT_READY     = -2
ERR_TRANSFER      = -3

EXP_NONE    = 0
EXP_NUNCHUK = 1
EXP_CLASSIC = 2
EXP_GH3     = 3

WPAD_Init()

cdef extern int _VICount

class Expansion:
    type = 'None'
    def __init__(self): self._dict = {}
    def __getitem__(self, b): return self._dict[b]
    def __setitem__(self, b, v): self._dict[b] = v

class Nunchuk(Expansion):
    type = 'Nunchuk'

cdef object processJoystick(joystick_t* js):
    cdef double angle
    angle = 3.14159 * js[0].ang / 180.0
    return ( js[0].mag * sin(angle), js[0].mag * cos(angle) )

cdef object processExpansion(WPADData* wpad):
    if wpad[0].exp.type == EXP_NUNCHUK:
        exp = Nunchuk()
        exp['C'] = wpad[0].btns_d & NUNCHUK_BUTTON_C
        exp['Z'] = wpad[0].btns_d & NUNCHUK_BUTTON_Z
        exp['GForce'] = ( wpad[0].exp.nunchuk.gforce.x,
                          wpad[0].exp.nunchuk.gforce.y,
                          wpad[0].exp.nunchuk.gforce.z )
        exp['Orient'] = ( wpad[0].exp.nunchuk.orient.pitch,
                          wpad[0].exp.nunchuk.orient.roll,
                          wpad[0].exp.nunchuk.orient.yaw )
        exp['Stick']  = processJoystick( &(wpad[0].exp.nunchuk.js) )
        return exp
    # TODO: Other expansions
    else: return Expansion()

class WPAD:
    """
    TODO: Document me!
    """
    def __init__(self, padNum):
        self.padNum = padNum
        self._VICount = -1
    def __getitem__(self, b):
        global _VICount
        if self._VICount != _VICount:
            self._update()
            self._VICount = _VICount
        
        return self._dict[b]
    
    def SetDataFormat(self, acc=False, ir=False):
        if ir:
            WPAD_SetDataFormat(self.padNum, FMT_CORE_ACC_IR)
        elif acc:
            WPAD_SetDataFormat(self.padNum, FMT_CORE_ACC)
        else:
            WPAD_SetDataFormat(self.padNum, FMT_CORE)
    
    def _update(self):
        cdef WPADData wpad
        WPAD_ReadEvent(self.padNum, &wpad)
        self._dict = { 'Up'    : wpad.btns_d & BUTTON_UP,
                       'Down'  : wpad.btns_d & BUTTON_DOWN,
                       'Left'  : wpad.btns_d & BUTTON_LEFT,
                       'Right' : wpad.btns_d & BUTTON_RIGHT,
                       'A'     : wpad.btns_d & BUTTON_A,
                       'B'     : wpad.btns_d & BUTTON_B,
                       '1'     : wpad.btns_d & BUTTON_1,
                       '2'     : wpad.btns_d & BUTTON_2,
                       '+'     : wpad.btns_d & BUTTON_PLUS,
                       '-'     : wpad.btns_d & BUTTON_MINUS,
                       'Home'  : wpad.btns_d & BUTTON_HOME,
                       'IR'    : ( wpad.ir.x, wpad.ir.y ),
                       'GForce': ( wpad.gforce.x, wpad.gforce.y, wpad.gforce.z ),
                       'Orient': ( wpad.orient.roll, wpad.orient.pitch, wpad.orient.yaw ),
                       'Exp'   : processExpansion(&wpad),
                       'Error' : wpad.err }
    

