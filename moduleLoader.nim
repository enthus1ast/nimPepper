# import tables
import pepperslaveImports
import json, dynlib
# import pepperslave
import typesPepperSlave
import asyncdispatch, tables

type
  SlaveCommandFunc[T] = proc(obj: T, params: JsonNode = nil): Future[JsonNode]
  # BoundCommand = 
  ModLoader[T] = ref object
    registeredCommands: Table[string, SlaveCommandFunc[T]]


proc newModLoader[T](): ModLoader[T] =
  result = ModLoader[T]()
  result.registeredCommands = initTable[string, SlaveCommandFunc[T]]()

proc call[T](loader: ModLoader, obj: T, name: string, params: JsonNode = nil): Future[JsonNode] {.async.} =
  ## Calls the registered command
  echo "[module] calling: ", name
  if not loader.registerCommand.has(name):
    echo "[module] command unknown: ", name
    raise 
  result = await loader.registeredCommands[name](params)
  echo "[module] ^^^ command calling done ^^^ "

# proc registerCommand[T](loader: ModLoader, obj: T, name: string, commandFunc: SlaveCommandFunc, doc: string = "") = 
proc registerCommand(loader: ModLoader, name: string, commandFunc: SlaveCommandFunc, doc: string = "") = 
  loader.registeredCommands.add(name, commandFunc)

proc loadDll(loader: ModLoader, path: string) = 
  let lib = loadLib(path)
  

when isMainModule:

  type SomeObj = object
    foo: string
  var dummyFunc: SlaveCommandFunc[SomeObj] = proc(obj: SomeObj, params: JsonNode): Future[JsonNode] {.async.} =
    echo "foo"
    echo "FOO:", obj.foo
    return (%* {})

  var boundObj = SomeObj(foo: "hallo 123")
  var modLoader = newModLoader[SomeObj]()
  modLoader.registerCommand("test.dummy", dummyFunc)
  # echo repr modLoader.registeredCommands
  echo waitFor modLoader.registeredCommands["test.dummy"](boundObj)
  # echo waitFor call[SomeObj](modLoader, boundObj, "test.dummy")

