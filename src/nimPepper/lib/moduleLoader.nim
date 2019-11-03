import dynlib, tables, os, strutils, tables
import asyncdispatch, json
export tables

type 
  ModLoader*[T] = ref object
    modules*: Table[string, T]

proc newModLoader*[T](): ModLoader[T] =
  result = ModLoader[T]()
  result.modules = initTable[string, T]()

proc registerModule*[T](modLoader: ModLoader[T], module: T) =
  modLoader.modules.add(module.name, module)

proc callInit*[M, O](module: M, obj: O, params: string): Future[void] {.async.} =
  if module.initProc.isNil: return
  discard await module.initProc(obj, params)

proc listCommands*[T](modLoader: ModLoader[T]): seq[string] =
  result = @[]
  for name, module in modLoader.modules:
    for command, commandProc in module.boundCommands:
      result.add name & "." & command

proc listModules*[T](modLoader: ModLoader[T]): seq[string] =
  result = @[]
  for name, module in modLoader.modules:
    result.add name

proc loadModule*[T](path, dllname: string): T = 
  ## loads given dll module and returns a SlaveModule
  var expandedPath = path / DynlibFormat % [dllname]
  echo "going to load: ", expandedPath
  var lib = loadLib(expandedPath)
  if lib == nil:
    raise newException(ValueError, "[loader] could not load: " & expandedPath)
  else:
    echo "[loader] loaded: ", expandedPath
  let modulePtr = lib.checkedSymAddr("mod" & dllname)
  if modulePtr.isNil:
    unloadLib(lib)
    raise newException(ValueError, "no module exported from dll:" & expandedPath )
  result = cast[ptr T](modulePtr)[]

proc splitCommand(cmd: string): tuple[moduleName, commandName: string] =
  let parts = cmd.split(".")
  if parts.len != 2: 
    raise newException(ValueError, "cmd is invalid: " & cmd)
  result.moduleName = parts[0]
  result.commandName = parts[1]

proc call*[T, boundObj](modLoader: ModLoader[T], obj: boundObj, name, params: string): Future[JsonNode] {.async.} = 
  echo "[module] calling: ", name

  var moduleName, commandName: string
  try:
    (moduleName, commandName) = name.splitCommand()
  except:
    return %* {"outp": "misformed command"}
  if not modLoader.modules.contains(moduleName):
    return %* {"outp": "unknown module: '$#'" % [moduleName]}
  var module = modLoader.modules[moduleName]
  if not module.boundCommands.contains(commandName):
    return %* {
      "outp": "module: '$#' unknown command: '$#' " % [moduleName, commandName]
    }
  result = await module.boundCommands[commandName](obj, params)

when isMainModule:
  import typesPepperSlave, typesModuleSlave
  var pepperSlave = PepperSlave()
  var modLoader = newModLoader[SlaveModule]()

  ### Dynamic loading
  var module = loadModule[SlaveModule]( getAppDir() / "modules/dummy/" ,"sdummy")
  modLoader.registerModule(module)
  echo modLoader.listCommands()
  echo "OUT:",  waitFor call[SlaveModule, PepperSlave](modLoader,pepperSlave, "dummy.dummy1", $ %*{})