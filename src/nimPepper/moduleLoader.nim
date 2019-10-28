import dynlib, tables, os, strutils, tables
import asyncdispatch, json
# import typesModuleSla
# import ../../moduleLoader.nim
export tables

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
    

# type
#   ## The obj that loads, the modules 
#   SlaveCommandFunc*[T] = proc(obj: T, params: string = ""): Future[JsonNode]
#   ModLoader*[T] = ref object
#     registeredCommands: Table[string, SlaveCommandFunc[T]]

# type Plol = proc() {.cdecl.}

when isMainModule:
  import typesPepperSlave, typesModuleSlave
  var pepperSlave = PepperSlave()
  var modLoader = newModLoader[SlaveModule]()

  ### Dynamic loading
  var module = loadModule[SlaveModule]( getAppDir() / "modules/dummy/" ,"sdummy")
  modLoader.registerModule(module)
  echo modLoader.listCommands()
  echo "OUT:",  waitFor call[SlaveModule, PepperSlave](modLoader,pepperSlave, "dummy.dummy1", $ %*{})
  
  
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






# # import tables
# import pepperslaveImports
# import json, dynlib
# import typesPepperSlave
# import asyncdispatch, tables
# import typesModule

# type
#   ## The obj that loads, the modules 
#   ModLoader*[T] = ref object
#     registeredCommands: Table[string, SlaveCommandFunc[T]]

# proc newModLoader[T](): ModLoader[T] =
#   result = ModLoader[T]()
#   result.registeredCommands = initTable[string, SlaveCommandFunc[T]]()

# proc call*[T](loader: ModLoader, obj: T, name: string, params: string = ""): Future[JsonNode] {.async.} =
#   ## Calls the registered command
#   echo "[module] calling: ", name
#   if not loader.registeredCommands.contains(name):
#     echo "[module] command unknown: ", name
#     # raise newException(ValueError, "command unknown: " & name)
#     result = %* {"outp": "command unknown: " & name}
#     # return
#   else:
#     result = await loader.registeredCommands[name](obj, params)
#   echo "[module] ^^^ command calling done ^^^ "

# proc registerCommand*[T](loader: ModLoader, obj: T, name: string, commandFunc: SlaveCommandFunc[T], doc: string = "") = 
#   loader.registeredCommands.add(name, commandFunc)

# proc listCommands*(loader: ModLoader): seq[string] = 
#   for module in loader.registeredCommands.keys:
#     result.add(module)

# # proc loadDll(loader: ModLoader, path: string) = 
# #   let lib = loadLib(path)


# # when isMainModule:
# #   import osproc
# #   type SomeObj = object
# #     foo: string
  
# #   var dummyFunc: SlaveCommandFunc[SomeObj] = proc(obj: SomeObj, params: string): Future[JsonNode] {.async.} =
# #     echo "foo"
# #     echo "FOO:", obj.foo
# #     return (%* {})

# #   var cmdOsShellExecute: SlaveCommandFunc[SomeObj] = proc(obj: SomeObj, params: string): Future[JsonNode] {.async.} =
# #     # result = JsonNode()
# #     let (outp, errC) = execCmdEx(params["cmd"].getStr())
# #     return (%* {
# #       "outp": outp,
# #       "errc": errC
# #     })
# #     # result["outp"] = %* outp
# #     # result["errc"] = %* errC

# #   var boundObj = SomeObj(foo: "hallo 123")
# #   var modLoader = newModLoader[SomeObj]()
# #   # modLoader.registerCommand("test.dummy", dummyFunc)
# #   modLoader.registerCommand(boundObj, "os.shell", cmdOsShellExecute)
# #   # echo repr modLoader.registeredCommands
# #   # echo waitFor modLoader.registeredCommands["test.dummy"](boundObj)
# #   # echo waitFor modLoader.registeredCommands["os.shell"](boundObj, %* {"cmd": "ifconfig"})
# #   echo waitFor modLoader.call(boundObj, "os.shell", %* {"cmd": "ifconfig -a"})
# #   echo waitFor modLoader.call(boundObj, "os.shell", %* {"cmd": "ping -c 1 google.de"})
# #   # echo waitFor call[SomeObj](modLoader, boundObj, "test.dummy")

