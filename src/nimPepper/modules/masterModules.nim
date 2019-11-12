## Add modules here that should be compiled into the pepperSlave executable
import ../lib/pepperdImports
import ../lib/typesPepperd

# Modules
import defaults/mping
import dummy/mdummy
# import defaults/mwww
import defaults/mupdate
import defaults/mmasterfind
import defaults/mtraps


proc register*(modLoader: ModLoader) =
  ## this function gets called by the pepperd, 
  ## every module that is registered here will be available in the final executable
  registerModule[MasterModule](modLoader, modmping)
  registerModule[MasterModule](modLoader, modmdummy)
  # registerModule[MasterModule](modLoader, modmwww)
  registerModule[MasterModule](modLoader, modmupdate)
  registerModule[MasterModule](modLoader, modmmasterfind)
  registerModule[MasterModule](modLoader, modmtraps)

