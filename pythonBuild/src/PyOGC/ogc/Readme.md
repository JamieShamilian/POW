
libogc wrappers

pyx files

"""
ogc Package
"""

cdef extern void initvideo()
cdef extern void initpad()
cdef extern void initaudio()
cdef extern void initlwp()
cdef extern void initnet()
cdef extern void initwpad()


def Init(console=True, mode=None, numFBs=2, initFat=True):



audio.pyx  lwp.pyx  ogc.pyx  pad.pyx  video.pyx  wpad.pyx

Create the C version of the python code by using pyrexc command included with python code base


audio.c  lwp.c  ogc.c  pad.c  vicount.c  video.c  wpad.c


