import ../../typesModuleSlave
import ../../typesPepperSlave
import ../../moduleLoader

# var module* {.exportc.} = newSlaveModule("defaults")
var modsping* {.exportc.} = newSlaveModule("defaults")

modsping.boundCommands["ping"] = proc(obj: PepperSlave, params: string): Future[JsonNode] {.async, closure.} =
  return %* {"outp": "pong"}

# proc register*[T](modLoader: ModLoader, boundObj: T) =
#   modLoader.registerCommand(boundObj, "ping", cmdPing)
