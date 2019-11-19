import ../../lib/typesPepperSlave
import ../../lib/moduleLoader
import os, strutils, httpclient

var modshttp* {.exportc.} = newSlaveModule("dynamic")

modshttp.boundCommands["download"] = proc(obj: PepperSlave, params: string): Future[JsonNode] {.async, closure.} =
  # loads 
  let (dir, lib ) = splitPath(params)
  try:
    var module = loadModule[SlaveModule](dir, lib)
    obj.modLoader.registerModule(module)
    return %* {"outp": "module loaded: " & dir / lib }
  except:
    return %* {"outp": "failed to load module: " & dir / lib & "\n" & getCurrentExceptionMsg()}