#/wiipy/run.py
import ogc
def listControllers(pads):
    print 'Controllers plugged in:',
    #for i in range(4):
    #    if pads[i]['Error'] != ogc.wpad.ERR_NO_CONTROLLER:
    #        print i
    #print
    
def loop(buttons,pads,lastPads):
    for button, function in buttons.iteritems():
        print "press %s to %s" % (button,function[0])
    while True:
            for i in range(4):
            	pads[i].update()
            	lastPads[i] = pads[i]._dict
                for button, function in buttons.iteritems():
                    if pads[i][button]:
			function[1](pads[i])
            ogc.video.WaitVSync()
def threadMethod(arg):
	import ogc
	return str(arg) + ' to you too from ' + str(ogc.lwp.GetSelf()) + '!'
def thread_start(pad):
	print 'Creating smallThread with argument: \'Hello\''
	smallThread = ogc.lwp.Thread(threadMethod, ('Hello',))
	print 'smallThread returned', smallThread.join()
def rumble_start(pad):
	pad.rumble_start()
def rumble_stop(pad):
	pad.rumble_stop()
def playSnake(pad):
	import ogc
	import _struct
        global xfb
        fb = xfb
        ogc.video.SetNextFramebuffer(fb[1])
	ogc.video.Flush()
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
		thread_start
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
	ogc.video.SetNextFramebuffer(fb[0])
	ogc.video.Flush()
def sd_start(pad):
	print 'Opening pyogc.txt to write...'
	try:
		f = open('pyogc.txt', 'w')
		f.write('Hello SD card from PyOGC!\n')
		print 'Success; closing file for writing'
		f.close()
		print 'The file says:', open('pyogc.txt').read()
	except:
		print 'Exception accessing file! Do you have an SD card in?'

def wiimoteDemo(wpad):
	import ogc
	import _struct
        global xfb
        ogc.video.SetNextFramebuffer(xfb[1])
        ogc.video.Flush()
        fb = xfb[1]
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
		if wpad['+']: break
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
        ogc.video.SetNextFramebuffer(xfb[0])
        ogc.video.Flush()

# Initialize libogc
xfb = ogc.Init()

# Get the Controllers
pads = ogc.wpad.WPAD(0), ogc.wpad.WPAD(1), ogc.wpad.WPAD(2), ogc.wpad.WPAD(3)

# Print a list of plugged in controllers
listControllers(pads)

# Get the Last touched buttons
lastPads = [pads[0]._dict, pads[1]._dict, pads[2]._dict, pads[3]._dict]

# List Buttons for each function
buttons={
'A': ['Rumbles Controller',rumble_start],
'B': ['Stops Rumbling',rumble_stop],
#'+': ['Play Snake',playSnake,xfb[1]],  # for some reason, snake makes ogc crash..
'-': ['wiimote demo',wiimoteDemo],
'1': ['Threading Demo',thread_start],
'2': ['SD Demo',sd_start]
}

#Start the loop
loop(buttons,pads,lastPads)

#END
