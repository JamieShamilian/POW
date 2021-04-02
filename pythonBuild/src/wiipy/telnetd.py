#! /usr/bin/env python
#/wiipy/telnetd.py

# Remote python server.
# Execute Python commands remotely and send output back.
# if files starts with '#/' this scripts store the file in SDCard
import net
import sys
from _socket import *
import StringIO
import traceback
wiipy_done = False
PORT = 23
try:
    if net.this_does_not_exists_on_wiipy:
        PORT = 2223 #allow us to run as user on linux
except:
    pass
BUFSIZE = 1024
def quit():
    global wiipy_done
    wiipy_done = True
def main():
    global PORT
    port = PORT
    s = socket(AF_INET, SOCK_STREAM)
    s.bind((gethostname(), port))
    s.listen(1)
    print "connect on your wii addr port",gethostname(),port
    try:
        while not wiipy_done:
            conn, add= s.accept()
            request = ''
            conn.send("type your python program, terminated by a '#END' line\n")
            conn.send("if your program begins with '#/<filename>', it will not be executed, but rather stored in FrontSD\n")
            conn.send("this is useful to populate your SDCard with python modules without ftpii or removing the sdcard\n")
            while 1:
                data = conn.recv(BUFSIZE)
                if not data :
                    break
                request = request + data
                if data.find("#END\n")!=-1:
                    break
            requst = request.replace("\r","")
            if request[0:2] =="#!": # skip first line if this is a python command
                request = request[request.find("\n")+1:]
            if request[0:2] =="#/": # this line asks us to save the file in SDCard instead of
                filename = request[1:request.find("\n")]
                if port >= 2222:
                    filename = "."+filename #write locally on linux
                f = open(filename,"w")
                f.write(request)
                f.close()
                print request
                print filename,"written to Front SD, not executing.."
                request=""
            else:
                reply = execute(request)
                try:
                    conn.send(reply)
                except: pass
                print reply
            conn.close()
    except:
        PORT+=1
        traceback.print_exc(100)
    s.close()
def execute(request):
    stdout = sys.stdout
    stderr = sys.stderr
    sys.stdout = sys.stderr = fakefile = StringIO.StringIO()
    try:
        try:
            exec request in {}, {"quit":quit}
        except:
            print
            traceback.print_exc(100)
    finally:
        sys.stderr = stderr
        sys.stdout = stdout
    return fakefile.getvalue()

def telnetd():
    num_try = 0
    while not wiipy_done and num_try<10:
        try:
           net.init()
        except:
           print "failed to init network. retry.."
        else:
            try:
                main()
            except:
                traceback.print_exc(100)
                PORT+=1
        num_try+=1
            
#END
