import ../../lib/typesPepperSlave
import ../../lib/moduleLoader
import strutils

when defined(windows):
  import getwin
elif defined(linux):
  import getlin
elif defined(macos):
  import getmac
# var module* {.exportc.} = newSlaveModule("defaults")
var modsdetect* {.exportc.} = newSlaveModule("detect")

proc getOs(): string =
  if defined(windows): 
    return "windows" 
  elif defined(linux): 
    return "linux"
  elif defined(macos):
    return "macos"
  elif defined(macosx):
    return "macosx"

proc getOsVer(): string = 
  when defined(windows):
    return $getWinVer()
  elif defined(linux):
    return $getLinVer()
  

modsdetect.boundCommands["detect"] = proc(obj: PepperSlave, params: string): Future[JsonNode] {.async, closure.} =
  return %* {
    # "outp": "NISCHT",
    # "json": {
    "os": getOs(),
    "osver": getOsVer()

    # }
    
  }

# modsdetect.boundCommands["substitutions"] = proc(obj: PepperSlave, params: string): Future[JsonNode] {.async, closure.} =
#   var res = ""
#   for key, val in obj.substitutionContext:
#     res.add "$#: $# \n" % [key ,val]
#   return %* {"outp": res}
