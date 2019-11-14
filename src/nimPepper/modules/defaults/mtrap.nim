# import ../../typesModuleSlave
import ../../lib/pepperdImports
import ../../lib/typesPepperd
import ../../lib/moduleLoader
import ../../lib/messages
import ../../lib/netfuncs
import ../../lib/pepperdFuncs
import asynchttpserver # for the httpCallback and httpAdminCallback
import strutils
import times
import ../../lib/httpfilesharing
# import matcher

# var module* {.exportc.} = newSlaveModule("defaults")
var modmtraps* {.exportc.} = newMasterModule("traps")


modmtraps.initProc = proc(obj: Pepperd, params: string): Future[JsonNode] {.async, closure.} =
  # asyncCheck obj.pingClients
  # echo "www INIT CALLED"
  createDir(getAppDir() / "www/slaves/linux")
  createDir(getAppDir() / "www/slaves/windows")
  createDir(getAppDir() / "www/slaves/macos")

# modmtraps.boundCommands["dummy"] = proc(obj: Pepperd, params: string): Future[JsonNode] {.async, closure.} =
#   echo "www COMMAND CALLED"
#   return %* {"outp": "pong"}

modmtraps.slaveConnects = proc(obj: Pepperd, client: Client): Future[void] {.async, closure.} =
  echo "WWW CLIENT CONNECTS:", client.peerAddr #, repr client
  ## check slave for version
  ## if version is old
  ##  initialize update process
  return

modmtraps.slaveDisconnects = proc(obj: Pepperd, client: Client): Future[void] {.async, closure.} =
  echo "WWW CLIENT DISCONNECTS:", client.peerAddr #repr client
  return

modmtraps.httpCallback = proc(obj: Pepperd, request: Request): Future[bool] {.async, closure.} =
  ## returns true if the http request was handled by this callback  
  if not ($request.url.path).startsWith("/www"):
    return false
  case $request.url.path
  of "/www/linux/latest/pepperslave":
    let slavePath = getLatest() / "pepperslave"
    if not fileExists(slavePath): 
      await request.respond(Http404, "not found")
      return
    var  slaveBinary = readFile(slavePath)
    await request.respond(Http200, slaveBinary )

  of "/www/slaves/windows/latest":
    await request.respond(Http200, "latest windows")
  else:
    return false
  return true

modmtraps.httpAdminCallback = proc(obj: Pepperd, request: Request): Future[bool] {.async, closure.} =
  ## returns true if the http request was handled by this callback
  if ($request.url.path).startsWith("/www"):
    await request.respond(Http200, "www")
    return true
  else:
    return false
