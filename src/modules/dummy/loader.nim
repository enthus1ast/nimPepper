import dynlib, tables, os, strutils, tables
import asyncdispatch, json
import ../../typesPepperSlave
import ../../typesModule
# import ../../moduleLoader.nim

type 
  ModLoader*[T] = ref object
    modules: Table[string, T]

proc newModLoader*[T](): ModLoader[T] =
  result = ModLoader[T]()
  result.modules = initTable[string, T]()

proc registerModule*[T](modLoader: ModLoader[T], module: T) =
  modLoader.modules.add(module.name, module)

proc listCommands*[T](modLoader: ModLoader[T]): seq[string] =
  result = @[]
  for name, module in modLoader.modules:
    for command, commandProc in module.boundCommands:
      result.add name & "." & command

proc loadModule*[T](path, dllname: string): T = 
  ## loads given dll module and returns a SlaveModule
  var expandedPath = path / DynlibFormat % [dllname]
  echo "going to load: ", expandedPath
  var lib = loadLib(expandedPath)
  if lib == nil:
    raise newException(ValueError, "[loader] could not load: " & expandedPath)
  else:
    echo "[loader] loaded: ", expandedPath
  let modulePtr = lib.checkedSymAddr("module")
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

proc call[T, boundObj](modLoader: ModLoader[T], obj: boundObj, name, params: string): Future[JsonNode] {.async.} = 
  echo "[module] calling: ", name
  let (moduleName, commandName) = name.splitCommand()
  if not modLoader.modules.contains(moduleName):
    return %* {"outp": "unknown module: '$#'" % [moduleName]}
  var module = modLoader.modules[moduleName]
  if not module.boundCommands.contains(commandName):
    return %* {
      "outp": "module: '$#' unknown command: '$#' " % [moduleName, commandName]
    }
  result = await module.boundCommands[commandName](obj, params)
    



# type
#   ## The obj that loads, the modules 
#   SlaveCommandFunc*[T] = proc(obj: T, params: string = ""): Future[JsonNode]
#   ModLoader*[T] = ref object
#     registeredCommands: Table[string, SlaveCommandFunc[T]]

# type Plol = proc() {.cdecl.}

when isMainModule:
  var pepperSlave = PepperSlave()
  var modLoader = newModLoader[SlaveModule]()
  var module = loadModule[SlaveModule]( getCurrentDir() ,"sdummy")
  modLoader.registerModule(module)
  echo modLoader.listCommands()
  echo waitFor call[SlaveModule, PepperSlave](modLoader,pepperSlave, "dummy.dummy1", $ %*{})
  ### Dynamic loading
  # block:
  #   echo "dynamic"
  #   echo module

    # for key, boundCommand in module.boundCommands:
    #   echo key, " -> ", waitFor boundCommand(pepperSlave, $ %* {})

# when isMainModule:
#   var pepperSlave = PepperSlave()

#   ### Dynamic loading
#   block:
#     echo "dynamic"
#     var module = loadModule[SlaveModule]( getCurrentDir() ,"sdummy")
#     echo module
#     for key, boundCommand in module.boundCommands:
#       echo key, " -> ", waitFor boundCommand(pepperSlave, $ %* {})
  
#   ### Static loading
#   import sdummy
#   block:
#     echo "static"
#     var module = sdummy.module
#     echo module
#     for key, boundCommand in module.boundCommands:
#       echo key, " -> ", waitFor boundCommand(pepperSlave, $ %* {})

# var exports = cast[ ptr seq[ (string, proc(obj: PepperSlave, params: string): Future[JsonNode]) ]  ](lib.checkedSymAddr("exports"))[]
# echo exports

# for exporta in exports:
#   echo exporta[0]
#   echo waitFor exporta[1](pepperSlave, "")

# echo repr exportsp

# var fptr = lib.checkedSymAddr("lol")
# var fnc = cast[Plol](fptr)
# fnc()


# type Pregister = proc (modLoader: ModLoader, boundObj: PepperSlave) {.cdecl.}
# var fptr2 = lib.checkedSymAddr("foo")
# # var fnc2 = cast[Plol](fptr2)


# var cstsp = lib.checkedSymAddr("ctst")
# echo cast[ptr cstring](cstsp)[]

# var ll: array[1024, (cstring,proc() {.cdecl.})]
# var llp = lib.checkedSymAddr("modules")
# if llp.isNil:
#   echo "modules is nil"
# else:
#   ll = cast[ array[1024, ( cstring,proc() {.cdecl.})] ](llp)
#   echo ll[0][0]

