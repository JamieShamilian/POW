import ogc, video
xfb = ogc.Init()
import sys
sys.path = ['/wiipy']

pad = ogc.wpad.WPAD(0)

#@todo not sure if this is the proper way not to use all cpu.
def home_return_thread(ign):
	print 'Press Home to return to hbc.'
	pad = ogc.wpad.WPAD(0)
	while True:
		pad.update()
		if pad["HOME"]:
			ogc.Reload()
		video.WaitVSync()
ogc.lwp.Thread(home_return_thread,(pad,))

def print_usage():
	print 'Press A to Run "/wiipy/run.py"'
	print 'Press B to Run the python telnet daemon'
def do_run():
	import run
def do_telnetd():
	import telnetd
	telnetd.telnetd()

print_usage()
while True:
	try:
		pad.update()
		if pad["A"]:
			do_run()
		if pad["B"]:
			do_telnetd()
		video.WaitVSync()
	except: 
		traceback.print_exc()
		print_usage()
