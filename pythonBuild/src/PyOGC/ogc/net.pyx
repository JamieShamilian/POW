import _socket
cdef extern from "network.h":
       int if_config(char *local_ip, char *netmask, char *gateway, char use_dhcp)
       int net_init()

def init():
       cdef char localip[36]
       cdef char gateway[36]
       cdef char netmask[36]
       cdef int retval
       retval = -11
       while retval == -11:
               retval = net_init()
       if retval != 0:
               raise _socket.error(retval, "Invalid return from net_init()")

       ret = if_config(localip, gateway, netmask, 1)
       if ret == 0:
               return (localip, gateway, netmask)
       else:
               raise _socket.error(ret, "Invalid return from if_config()")
