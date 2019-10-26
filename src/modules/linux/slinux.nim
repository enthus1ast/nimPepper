import ../../typesModuleSlave
import ../../typesPepperSlave
import ../../moduleLoader
import strutils

# var module* {.exportc.} = newSlaveModule("defaults")
var modslinux* {.exportc.} = newSlaveModule("defaults")

proc isSystemd(): bool = 
  ## if system was booted with systemd
  # https://www.freedesktop.org/software/systemd/man/sd_booted.html
  existsDir("/run/systemd/system/")

modslinux.boundCommands["isSystemd"] = proc(obj: PepperSlave, params: string): Future[JsonNode] {.async, closure.} =
  return %* {"outp": $isSystemd()}

# modslinux.boundCommands["substitutions"] = proc(obj: PepperSlave, params: string): Future[JsonNode] {.async, closure.} =
#   var res = ""
#   for key, val in obj.substitutionContext:
#     res.add "$#: $# \n" % [key ,val]
#   return %* {"outp": res}
