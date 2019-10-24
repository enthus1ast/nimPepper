import ../../typesModuleSlave
import ../../typesPepperSlave
import ../../moduleLoader
import os, strutils

# var module* {.exportc.} = newSlaveModule("defaults")
var modsdynamic* {.exportc.} = newSlaveModule("dynamic")

modsdynamic.boundCommands["load"] = proc(obj: PepperSlave, params: string): Future[JsonNode] {.async, closure.} =
  # loads 
  try:
    let (dir, lib ) = splitPath(params)
    var module = loadModule[SlaveModule](dir, lib)
    obj.modLoader.registerModule(module)
    return %* {"outp": "module loaded: " & getAppDir() / "modules/" & params }
  except:
    return %* {"outp": "failed to load module: " & getAppDir() / "modules/" & params & "\n" & getCurrentExceptionMsg() }

modsdynamic.boundCommands["list"] = proc(obj: PepperSlave, params: string): Future[JsonNode] {.async, closure.} =
  return %* {"outp": obj.modLoader.listModules().join("\n")}

# proc register*[T](modLoader: ModLoader, boundObj: T) =
#   modLoader.registerCommand(boundObj, "ping", cmdPing)
