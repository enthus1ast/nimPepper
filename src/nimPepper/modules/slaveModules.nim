## Add modules here that should be compiled into the pepperSlave executable
import ../lib/pepperslaveImports

# Modules:
import os/sshell
import defaults/sping
import defaults/sdynamic
import defaults/sdetect
import defaults/spac
import defaults/supdate

proc register*[T](modLoader: ModLoader, boundObj: T) =
  ## this function gets called by the papperSlave, 
  ## every module that is registered here will be available in the final executable
  registerModule[SlaveModule](modLoader, modsshell )
  registerModule[SlaveModule](modLoader, modsping)
  registerModule[SlaveModule](modLoader, modsdynamic)
  registerModule[SlaveModule](modLoader, modsdetect)
  registerModule[SlaveModule](modLoader, modspac)
  registerModule[SlaveModule](modLoader, modsupdate)
