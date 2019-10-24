import dynlib, tables
import asyncdispatch, json
import ../../typesPepperSlave
import ../../typesModule
# import ../../moduleLoader.nim

var lib = loadLib("./libsdummy.so")
if lib == nil:
  echo "could not load"
else:
  echo "loaded"

# type
#   ## The obj that loads, the modules 
#   SlaveCommandFunc*[T] = proc(obj: T, params: string = ""): Future[JsonNode]
#   ModLoader*[T] = ref object
#     registeredCommands: Table[string, SlaveCommandFunc[T]]

# type Plol = proc() {.cdecl.}

var pepperSlave = PepperSlave()

var module = cast[ ptr SlaveModule ](lib.checkedSymAddr("module"))[]
echo module
for key, boundCommand in module.boundCommands:
  echo key, " -> ", waitFor boundCommand(pepperSlave, $ %* {})

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

