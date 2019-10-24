# import tables
import pepperslaveImports
import json, dynlib
import typesPepperSlave
import asyncdispatch, tables
import typesModule

type
  ## The obj that loads, the modules 
  ModLoader*[T] = ref object
    registeredCommands: Table[string, SlaveCommandFunc[T]]

proc newModLoader[T](): ModLoader[T] =
  result = ModLoader[T]()
  result.registeredCommands = initTable[string, SlaveCommandFunc[T]]()

proc call*[T](loader: ModLoader, obj: T, name: string, params: string = ""): Future[JsonNode] {.async.} =
  ## Calls the registered command
  echo "[module] calling: ", name
  if not loader.registeredCommands.contains(name):
    echo "[module] command unknown: ", name
    # raise newException(ValueError, "command unknown: " & name)
    result = %* {"outp": "command unknown: " & name}
    # return
  else:
    result = await loader.registeredCommands[name](obj, params)
  echo "[module] ^^^ command calling done ^^^ "

proc registerCommand*[T](loader: ModLoader, obj: T, name: string, commandFunc: SlaveCommandFunc[T], doc: string = "") = 
  loader.registeredCommands.add(name, commandFunc)

proc listCommands*(loader: ModLoader): seq[string] = 
  for module in loader.registeredCommands.keys:
    result.add(module)

# proc loadDll(loader: ModLoader, path: string) = 
#   let lib = loadLib(path)


# when isMainModule:
#   import osproc
#   type SomeObj = object
#     foo: string
  
#   var dummyFunc: SlaveCommandFunc[SomeObj] = proc(obj: SomeObj, params: string): Future[JsonNode] {.async.} =
#     echo "foo"
#     echo "FOO:", obj.foo
#     return (%* {})

#   var cmdOsShellExecute: SlaveCommandFunc[SomeObj] = proc(obj: SomeObj, params: string): Future[JsonNode] {.async.} =
#     # result = JsonNode()
#     let (outp, errC) = execCmdEx(params["cmd"].getStr())
#     return (%* {
#       "outp": outp,
#       "errc": errC
#     })
#     # result["outp"] = %* outp
#     # result["errc"] = %* errC

#   var boundObj = SomeObj(foo: "hallo 123")
#   var modLoader = newModLoader[SomeObj]()
#   # modLoader.registerCommand("test.dummy", dummyFunc)
#   modLoader.registerCommand(boundObj, "os.shell", cmdOsShellExecute)
#   # echo repr modLoader.registeredCommands
#   # echo waitFor modLoader.registeredCommands["test.dummy"](boundObj)
#   # echo waitFor modLoader.registeredCommands["os.shell"](boundObj, %* {"cmd": "ifconfig"})
#   echo waitFor modLoader.call(boundObj, "os.shell", %* {"cmd": "ifconfig -a"})
#   echo waitFor modLoader.call(boundObj, "os.shell", %* {"cmd": "ping -c 1 google.de"})
#   # echo waitFor call[SomeObj](modLoader, boundObj, "test.dummy")

