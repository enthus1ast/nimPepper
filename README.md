tl;dr
======

pepper is a remote code execution system to control multiple computers
at once, from a master computer. The system consists of 3 core components:

1. The master (pepperd):
  Slaves connect to the master, the master sends commands to the slaves.
2. The slaves (pepperslave):
  Slaves run on computers that should be controlled. Slaves connect to the master and waits for commands.
3. The control tool (pepper):
  The control tool is used by administrators to send commands through the master to the 
  slaves.


modules
=======

nearly every feature a slave has, is implemented by modules.
There are two ways to add features to the slave.
Either by compile modules into the slave. 
This requires pepperslave recompilation.
Or load a module (*.dll or *.so) on runtime.

The master can also be extendet by modules. This however is not implemented fully yet.

slave: compile modules into the slave
------------------------------


slave: load modules on runtime
--------------------------------------


test ws
======

```
wscat -c ws://127.0.0.1:8989 -s pepper
{"raw": "raw", "senderPublicKey": "key", "signature": "signature"}
{"raw": "raw", "senderPublicKey": "PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP", "signature": "SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS"}

```
