# import ../../typesModuleSlave
import ../../lib/pepperdImports
import ../../lib/typesPepperd
import ../../lib/moduleLoader
import ../../lib/messages
import ../../lib/netfuncs
import ../../lib/pepperdFuncs
import strutils
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