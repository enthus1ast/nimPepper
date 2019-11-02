# import ../typesPepperSlave
# import ../pepperslaveImports
import ../pepperdImports
import ../typesPepperd
## Add modules here that should be compiled into the pepperSlave executable
# from os/sshell import nil
# from defaults/sping import nil

import defaults/mping
import dummy/mdummy
# import os/sshell
# import defaults/sping
# import defaults/sdynamic

## Also call register of each module
proc register*(modLoader: ModLoader) =
  ## this function gets called by the papperSlave, 
  ## every module that is registered here will be available in the final executable
  # registerModule[MasterModule](modLoader, modsshell )
  registerModule[MasterModule](modLoader, modmping)
  registerModule[MasterModule](modLoader, modmdummy)
  # registerModule[MasterModule](modLoader, modsdynamic)
  # sshell.register(modLoader, boundObj)
  # sping.register(modLoader, boundObj)