import ../../lib/typesPepperSlave
import ../../lib/moduleLoader
import ../../lib/pepperslaveImports
import strutils
import httpclient
import os

# var module* {.exportc.} = newSlaveModule("defaults")
var modsupdate* {.exportc.} = newSlaveModule("updates")

let ExeFormat = "$#" & ExtSep & ExeExt
proc formatExe(exe: string): string = 
  return addFileExt(exe, ExeExt)

proc tryMoveFile(src, dst: string): bool =
  echo src , " > ", dst
  try:
    moveFile(src, dst)
    return true
  except:
    return false

modsupdate.boundCommands["update"] = proc(obj: PepperSlave, params: string): Future[JsonNode] {.async, closure.} =
  let masterHost = obj.configSlave.getSectionValue("master", "server")
  let masterPort = obj.configSlave.getSectionValue("master", "port").parseInt
  var client = newHttpClient()
  var url = ""
  when defined(linux):
    url = "/www/linux/latest/pepperslave"
  elif defined(windows):
    url = "/www/windows/latest/pepperslave"
  let blob = client.getContent("http://$#:$#$#" % [masterHost, $masterPort, url])
  echo "downloaded"
  writeFile(getAppDir() / "_pepperslave".formatExe , blob)
  discard tryRemoveFile(getAppDir() / "bak.pepperslave".formatExe)
  discard tryMoveFile(
    getAppDir() / "pepperslave".formatExe, 
    getAppDir() / "bak.pepperslave".formatExe
  )
  discard tryMoveFile(
    getAppDir() / "_pepperslave".formatExe, 
    getAppDir() / "pepperslave".formatExe
  )
  inclFilePermissions(getAppDir() / "pepperslave".formatExe, {fpUserExec})
  if true:
    quit()
  return %* {"outp": "pong"}

# modsupdate.boundCommands["substitutions"] = proc(obj: PepperSlave, params: string): Future[JsonNode] {.async, closure.} =
#   var res = ""
#   for key, val in obj.substitutionContext:
#     res.add "$#: $# \n" % [key ,val]
#   return %* {"outp": res}
