# import ../typesPepperSlave
import ../pepperslaveImports
## Add modules here that should be compiled into the pepperSlave executable
import os/sshell
# export sshell

## Also call register of each module
proc register*[T](modLoader: ModLoader, boundObj: T) =
  ## this function gets called by the papperSlave, 
  ## every module that is registered here will be available in the final executable
  sshell.register(modLoader, boundObj)