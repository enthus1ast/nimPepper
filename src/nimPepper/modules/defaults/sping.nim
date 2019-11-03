import ../../lib/typesPepperSlave
import ../../lib/moduleLoader
import strutils

# var module* {.exportc.} = newSlaveModule("defaults")
var modsping* {.exportc.} = newSlaveModule("defaults")

modsping.boundCommands["ping"] = proc(obj: PepperSlave, params: string): Future[JsonNode] {.async, closure.} =
  return %* {"outp": "pong"}

modsping.boundCommands["substitutions"] = proc(obj: PepperSlave, params: string): Future[JsonNode] {.async, closure.} =
  var res = ""
  for key, val in obj.substitutionContext:
    res.add "$#: $# \n" % [key ,val]
  return %* {"outp": res}
