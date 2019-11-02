# import ../../typesModuleSlave
import ../../pepperdImports
import ../../typesPepperd
import ../../moduleLoader
import ../../messages
import ../../netfuncs
import strutils
import ../../pepperdFuncs

import times

# var module* {.exportc.} = newSlaveModule("defaults")
var modmdummy* {.exportc.} = newMasterModule("dummy")


modmdummy.initProc = proc(obj: Pepperd, params: string): Future[JsonNode] {.async, closure.} =
  # asyncCheck obj.pingClients
  echo "DUMMY INIT CALLED"

modmdummy.boundCommands["dummy"] = proc(obj: Pepperd, params: string): Future[JsonNode] {.async, closure.} =
  echo "DUMMY COMMAND CALLED"
  return %* {"outp": "pong"}

modmdummy.slaveConnects = proc(obj: Pepperd, client: Client): Future[void] {.async, closure.} =
  echo "CLIENT CONNECTS:", client.peerAddr #, repr client
  return

modmdummy.slaveDisconnects = proc(obj: Pepperd, client: Client): Future[void] {.async, closure.} =
  echo "CLIENT DISCONNECTS:", client.peerAddr #repr client
  return