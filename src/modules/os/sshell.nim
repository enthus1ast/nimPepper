import ../../typesModule
import ../../typesPepperSlave
import ../../moduleLoader
import osproc, sequtils

var cmdOsShellExecute*: SlaveCommandFunc[PepperSlave] = proc(obj: PepperSlave, params: string): Future[JsonNode] {.async.} =
  ## Runs a command with the system shell, blocks until the command is finished
  let (outp, errC) = execCmdEx(params)
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


proc register*[T](modLoader: ModLoader, boundObj: T) =
  modLoader.registerCommand(boundObj, "os.shell", cmdOsShellExecute)
  # modLoader.registerCommand(boundObj, "os.spawn", cmdOsSpawn)

# when isMainModule:
#   echo waitFor modLoader.call(boundObj, "os.shell", %* {"cmd": "ifconfig -a"})
#   echo waitFor modLoader.call(boundObj, "os.shell", %* {"cmd": "ping -c 1 google.de"})  