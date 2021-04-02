"""
Demo of using libogc in Pyrex
"""

# get stuff we need from C header files

cdef extern from "Python.h":
	# embedding funcs
	void Py_Initialize()
	void Py_Finalize()
	void PySys_SetArgv(int argc, char **argv)
	# declare any other Python/C API functions we might need
	void Py_INCREF(object o)
	void Py_DECREF(object o)
	object PyString_FromStringAndSize(char *, int)
	object PyBuffer_FromReadWriteMemory(void*, int)

cdef extern short wavefile[]

# IMPORTANT - we need to explicitly prototype the function
# 'init<mymodulename>()', where 'mymodulename' is the
# filename this code resides in. I called the file 'demo.pyx',
# hence the name below

cdef extern void initdemo()
cdef extern void initogc()
cdef extern void init_struct()

# Now, need to declare the needed C main() function

cdef public int main(int argc, char **argv):
	# warm up python
	Py_Initialize()
	
	initdemo() # mandatory
	init_struct() # we use this module later
	
	# init libogc modules
	initogc()
	import ogc
	
	try:
		Main()
	except Exception, e:
		xfb = ogc.Init(numFBs=1)[0]
		ogc.video.SetNextFramebuffer(xfb)
		ogc.video.Flush()
		print '\n\n\n\n'
		print 'Caught exception', e, 'in Main'
		print 'Press Z to return to loader'
		pad = ogc.pad.PAD(0)
		while not pad['Z']: ogc.video.WaitVSync()
	
	return 0

def Main():
	import ogc
	# Initialize libogc
	xfb = ogc.Init()
	
	# Initialization done - we can now do Python stuff
	print
	print '***************************************'
	print '*             PyOGC Demo              *'
	print '***************************************'
	print
	
	
	# Creating PAD and WPAD objects for each pad
	pads  = ogc.pad.PAD(0), ogc.pad.PAD(1), ogc.pad.PAD(2), ogc.pad.PAD(3)
	wpads = ogc.wpad.WPAD(0), ogc.wpad.WPAD(1), ogc.wpad.WPAD(2), ogc.wpad.WPAD(3)
	
	# Print a list of plugged in controllers
	print 'Controllers plugged in:',
	for i in range(4):
		if pads[i]['Error'] == ogc.pad.ERR_NONE:
			print i,
	print
	
	print 'Press START'
	while not pads[0]['Start']: ogc.video.WaitVSync()
	print
	
	# Infinite loop
	print 'Press A to rumble, B to stop'
	print 'X plays an audio clip'
	print 'Y plays framebuffer snake'
	print 'Z returns to loader'
	print 'L writes to SD'
	lastPads = [pads[0]._dict, pads[1]._dict, pads[2]._dict, pads[3]._dict]
	while True:
		for i in range(4):
			# Wiimote Demo
			if wpads[i]['A']:
				ogc.video.SetNextFramebuffer(xfb[1])
				ogc.video.Flush()
				wiimoteDemo(wpads[i], xfb[1])
				ogc.video.SetNextFramebuffer(xfb[0])
				ogc.video.Flush()
			
			# Only execute commands when pads have changed
			changed = False
			for b in ogc.pad.buttons:
				if pads[i][b] != lastPads[i][b]: changed = True
			
			if changed:
				lastPads[i] = pads[i]._dict
				# Rumble Demo
				if pads[i]['A']:
					pads[i].rumble_start()
				if pads[i]['B']:
					pads[i].rumble_stop()
				# Reload
				if pads[i]['Z']:
					ogc.audio.Stop()
					ogc.Reload();
				# Audio Demo
				if pads[i]['X']:
					playSound()
				# Framebuffer Demo
				if pads[i]['Y']:
					ogc.video.SetNextFramebuffer(xfb[1])
					ogc.video.Flush()
					playSnake(pads[i], xfb[1])
					ogc.video.SetNextFramebuffer(xfb[0])
					ogc.video.Flush()
				# Threading Demo
				if pads[i]['R']:
					print 'Creating smallThread with argument: \'Hello\''
					smallThread = ogc.lwp.Thread(threadMethod, ('Hello',))
					print 'smallThread returned', smallThread.join()
				# SD Card Demo
				if pads[i]['L']:
					print 'Opening pyogc.txt to write...'
					try:
						f = open('pyogc.txt', 'w')
						f.write('Hello SD card from PyOGC!\n')
						print 'Success; closing file for writing'
						f.close()
						print 'The file says:', open('pyogc.txt').read()
					except:
						print 'Exception accessing file! Do you have an SD card in?'
		# No need to poll the controllers more often
		#   than the values are actually updated
		ogc.video.WaitVSync()
	
	return 0

def playSound():
	import ogc
	global wavefile
	
	# Read the samples into a list
	print 'Processing wave'
	# Static size for this specific clip
	cdef int buffersize
	buffersize = 0x1D600
	# Create a buffer object to pass
	samples = PyBuffer_FromReadWriteMemory(wavefile, buffersize)
	# Play it
	print 'Playing wave'
	try: ogc.audio.Play(samples, ogc.audio.SAMPLERATE_32KHZ)
	except IOError: print 'Wait for the previous sample to finish'

def threadMethod(arg):
	import ogc
	return str(arg) + ' to you too from ' + str(ogc.lwp.GetSelf()) + '!'

def playSnake(pad, fb):
	import ogc
	import _struct
	pxlpr = _struct.Struct('L')
	fbuffer = fb.get_buffer()
	fb.clear(ogc.video.COLOR_SKYBLUE)
	
	N, E, S, W = (0,-1), (1,0), (0,1), (-1,0)
	MAX_X, MAX_Y = 319, 479
	GROWTH_FRAMES = 20
	snake = [ (160,240) ]
	direction = E
	frames_till_growth = 0
	paused = False
	
	while True:
		# Handle input
		if pad['Up']: direction = N
		elif pad['Down']: direction = S
		elif pad['Left']: direction = W
		elif pad['Right']: direction = E
		
		if pad['X']: break
		elif pad['Start']: paused = not paused
		
		# If paused, don't execute the game
		if paused:
			ogc.video.WaitVSync()
			continue
		# Find next position
		x = snake[-1][0] + direction[0]
		y = snake[-1][1] + direction[1]
		if x < 0: x = MAX_X
		elif x > MAX_X: x = 0
		if y < 0: y = MAX_Y
		elif y > MAX_Y: y = 0
		# Check if we've run into ourselves
		collision = False
		for x2,y2 in snake:
			if x==x2 and y==y2:
				collision = True
				break
		if collision: break
		# Remove the end of the tail unless we grew
		if frames_till_growth > 0:
			frames_till_growth = frames_till_growth - 1
			snake = snake[1:]
		else:
			frames_till_growth = GROWTH_FRAMES
		snake.append( (x,y) )
		# Actually draw the snake
		fb.clear(ogc.video.COLOR_SKYBLUE)
		for i,j in snake:
			pxlpr.pack_into(fbuffer, 2*640*j+4*i, ogc.video.COLOR_GREEN)
		ogc.video.WaitVSync()
	
	fb.clear(ogc.video.COLOR_RED)
	for i in range(30): ogc.video.WaitVSync()

def wiimoteDemo(wpad, fb):
	import ogc
	import _struct
	pxlpr = _struct.Struct('L')
	fbuffer = fb.get_buffer()
	fb.clear(ogc.video.COLOR_WHITE)
	# Enable IR reporting
	wpad.SetDataFormat(ir=True)
	# Create an empty 'image' which will populated by x,y coords
	image = []
	
	while True:
		# Handle input
		x, y = wpad['IR']
		if wpad['Home']: break
		if wpad['A'] and x < 320 and y < 640 and x >= 0 and y >= 0:
			image.append( (x,y) )
		
		# Actually draw everything
		fb.clear(ogc.video.COLOR_WHITE)
		try:
			# Draw all the black
			for i,j in image:
				pxlpr.pack_into(fbuffer, 2*640*j+4*i, ogc.video.COLOR_BLACK)
			# Draw the pointer
			pxlpr.pack_into(fbuffer, 2*640*y    +4*x,     ogc.video.COLOR_RED)
			pxlpr.pack_into(fbuffer, 2*640*(y-1)+4*x,     ogc.video.COLOR_RED)
			pxlpr.pack_into(fbuffer, 2*640*     +4*(x-1), ogc.video.COLOR_RED)
			pxlpr.pack_into(fbuffer, 2*640*(y+1)+4*x,     ogc.video.COLOR_RED)
			pxlpr.pack_into(fbuffer, 2*640*y    +4*(x+1), ogc.video.COLOR_RED)
		except:
			pass
		ogc.video.WaitVSync()
	# Play nicely and turn off acc/ir when not in use
	wpad.SetDataFormat(False, False)

