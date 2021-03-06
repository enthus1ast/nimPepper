import ../../lib/typesPepperSlave
import ../../lib/moduleLoader
import osproc, sequtils, parseopt

# var module* {.exportc.} = newSlaveModule("os")
var modsshell* {.exportc.} = newSlaveModule("os")


modsshell.boundCommands["shell"] = proc(obj: PepperSlave, params: string): Future[JsonNode] {.async, closure.} =
  ## Runs a command with the system shell, blocks until the command is finished
  var outp: string
  var errC: int
  try:
    (outp, errC) = execCmdEx(params)
  except:
    outp = "Could not execute (not found?): " & getCurrentExceptionMsg()
  return (%* {
    "outp": outp,
    "errc": errC
  })

# var cmdOsSpawn*: SlaveCommandFunc[PepperSlave] = proc(obj: PepperSlave, params: JsonNode): Future[JsonNode] {.async.} =
#   ## Spawns a new process, does not block.
#   var outp = ""
#   try:
#     let process = startProcess(
#       command = params["command"].getStr(),
#       workingDir = params["workingDir"].getStr(""),
#       args = params["args"].getElems().map(proc(x: JsonNode): string = x.getStr())
#     )
#   except:
#     outp = getCurrentExceptionMsg()
#   return (%* {
#     "outp": outp,
#     # "errc": errC
#   })


# proc register*[T](modLoader: ModLoader, boundObj: T) =
#   modLoader.registerCommand(boundObj, "os.shell", cmdOsShellExecute)
#   # modLoader.registerCommand(boundObj, "os.spawn", cmdOsSpawn)

# when isMainModule:
#   echo waitFor modLoader.call(boundObj, "os.shell", %* {"cmd": "ifconfig -a"})
#   echo waitFor modLoader.call(boundObj, "os.shell", %* {"cmd": "ping -c 1 google.de"})  