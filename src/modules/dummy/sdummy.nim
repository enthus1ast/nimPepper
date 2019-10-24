import ../../typesModule
import ../../typesPepperSlave
# import ../../moduleLoader
import tables
# import osproc, sequtils


#############################
# import ../../


var moduleVar = "some var"
var module* {.exportc.} = newSlaveModule("dummy")
module.initProc = proc(obj: PepperSlave, params: string): Future[JsonNode] {.async, closure.} =
  return (%* {
    "outp": "INIT"
  })

module.boundCommands["dummy1"] = proc(obj: PepperSlave, params: string): Future[JsonNode] {.async, closure.} =
  return (%* {
    "outp": "dummy1: " & moduleVar
  })

module.boundCommands["dummy2"] = proc(obj: PepperSlave, params: string): Future[JsonNode] {.async, closure.} =
  return (%* {
    "outp": "dummy2: " & moduleVar
  })


module.unInitProc = proc(obj: PepperSlave, params: string): Future[JsonNode] {.async, closure.} =
  return (%* {
    "outp": "UNINIT"
  })

# var cmdDummy*: SlaveCommandFunc[PepperSlave] = proc(obj: PepperSlave, params: string): Future[JsonNode] {.async.} =
#   ## Runs a command with the system shell, blocks until the command is finished
#   # let (outp, errC) = execCmdEx(params)
#   return (%* {
#     "outp": "DUMMY"
#     # "errc": errC
#   })
# type
  # Duhm = proc(obj: PepperSlave, params: string): Future[JsonNode]

var cmdDummy1* = proc(obj: PepperSlave, params: string): Future[JsonNode] {.async, closure.} =
  ## Runs a command with the system shell, blocks until the command is finished
  # let (outp, errC) = execCmdEx(params)
  return (%* {
    "outp": "DUMMY1"
    # "errc": errC
  })

var cmdDummy2* = proc(obj: PepperSlave, params: string): Future[JsonNode] {.async, closure.} =
  ## Runs a command with the system shell, blocks until the command is finished
  # let (outp, errC) = execCmdEx(params)
  return (%* {
    "outp": "DUMMY2"
    # "errc": errC
  })

var exports* {.exportc.}: seq[ (string, proc(obj: PepperSlave, params: string): Future[JsonNode]) ] = @[
  ("dummy1", cmdDummy1),
  ("dummy2", cmdDummy2)
]

# proc lol*() {.cdecl, exportc, dynlib.} =
#   echo "LOL"



# type SlaveModLoader = object
#   registeredCommands: Table[string, SlaveCommandFunc]

# proc foo*[T](known: Known, boundObj: T) {.cdecl, exportc, dynlib.} =
# proc foo*(modLoader: ModLoader, boundObj: PepperSlave) {.cdecl, exportc, dynlib.} =
# proc foo*(modLoader: ModLoader) {.cdecl, exportc, dynlib.} =
#   echo "FOO"
  # modLoader.registerCommand(boundObj, "dummy.dummy", cmdDummy)
  # modLoader.registerCommand(boundObj, "os.spawn", cmdOsSpawn)


# var modules {.exportc, dynlib.}: array[1024, (cstring, proc() {.cdecl.})]
# var comname = "os.lol".cstring
# modules[0] = (comname, lol)

# var ctst {.exportc, dynlib.}: cstring = "halloichbinda"

# when isMainModule:
#   echo waitFor modLoader.call(boundObj, "os.shell", %* {"cmd": "ifconfig -a"})
#   echo waitFor modLoader.call(boundObj, "os.shell", %* {"cmd": "ping -c 1 google.de"})  