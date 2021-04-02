"""
lwp Package
"""

ctypedef void PyObject

cdef extern from "ogc/lwp.h":
	ctypedef unsigned int lwp_t
	int LWP_CreateThread(lwp_t*, void* (*)(void*), object arg, void* stack, unsigned int stsize, unsigned char prio)
	int LWP_SuspendThread(lwp_t)
	int LWP_ResumeThread(lwp_t)
	int LWP_ThreadIsSuspended(lwp_t)
	lwp_t LWP_GetSelf()
	void LWP_SetThreadPriority(lwp_t, unsigned int)
	void LWP_YieldThread()
	void LWP_Reschedule(unsigned int)
	int LWP_JoinThread(lwp_t, void** return_value)
	# TODO: Wrap lwpq as well

cdef extern from "ogc/semaphore.h":
	ctypedef unsigned int sem_t
	int LWP_SemInit(sem_t*, unsigned int start, unsigned int max)
	int LWP_SemDestroy(sem_t)
	int LWP_SemWait(sem_t)
	int LWP_SemPost(sem_t)
	
cdef extern from "Python.h":
	void Py_INCREF(object o)
	void Py_DECREF(object o)

# TODO: Create a Thread object for the main thread

# FIXME: Threads need to be removed from _threads, but when?
_threads = { }
cdef sem_t _threadsLock
LWP_SemInit(&_threadsLock, 1, 1)

def GetSelf():
	# Ensure _threads is up to date
	LWP_SemWait(_threadsLock)
	self = _threads[LWP_GetSelf()]
	LWP_SemPost(_threadsLock)
	return self

cdef void* _thread_stub(object methNArgs):
	meth, args = methNArgs
	Py_DECREF(methNArgs)
	return_value = meth(*args)
	Py_INCREF(return_value)
	print 'returning', return_value, '@', hex(<unsigned int><void*>return_value)
	return <void*>return_value

cdef class Thread:
	
	cdef lwp_t handle
	
	def __cinit__(self, meth, args, priority=80, stack_size=0):
		cdef lwp_t tmp_handle
		methNArgs = (meth,args)
		Py_INCREF(methNArgs)
		LWP_SemWait(_threadsLock)
		if LWP_CreateThread(&tmp_handle, <void* (*)(void*)>_thread_stub, methNArgs, NULL, stack_size, priority) < 0:
			raise SystemError
		self.handle = tmp_handle
		# Add this thread to the dictionary of threads
		_threads[self.handle] = self
		LWP_SemPost(_threadsLock)
	
	def __repr__(self):
		return '<lwp.Thread ' + str(self.handle) + '>'
	
	def yield_thread(self):
		LWP_YieldThread()
	def suspend(self):
		return LWP_SuspendThread(self.handle)
	def resume(self):
		return LWP_ResumeThread(self.handle)
	def is_suspended(self):
		return LWP_ThreadIsSuspended(self.handle) != 0
	def set_priority(self, priority):
		LWP_SetThreadPriority(self.handle, priority)
	def join(self):
		cdef void* return_value
		if LWP_JoinThread(self.handle, &return_value) < 0:
			raise SystemError
		# TODO: Restore this to return properly when its fixed in libogc
		#print 'Thread returned', <object>return_value, '@', hex(<unsigned int>return_value)
		#print
		return None #return <object>return_value


