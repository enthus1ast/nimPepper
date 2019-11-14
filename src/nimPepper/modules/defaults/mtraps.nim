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
import parseToml
import trapshared
import flatdb
import tables
import ../../lib/parseTomlDates
# import ../../lib/httpfilesharing
# import matcher


let trapconfig = getAppDir() / "/traps/mastertraps.toml"
let trapfolder = getAppDir() / "/traps/"

var dbs: Table[string, FlatDb]
var modmtraps* {.exportc.} = newMasterModule("traps")
var traps: TomlValueRef
var currentState: JsonNode = %* {}

proc genName(trap: string): string =
  trapfolder / trap & ".jsonl"

proc isAlarm(trap: string): bool =
  ## checks trap if is in alarming state
  let entry = dbs[trap].queryOneReverse(equal("trap", trap))
  if entry.isNil:
    #echo "TODO NO OLD TRAP TRIGGER FOR ", trap
    return true
  let trapTrigger = entry.to(TrapTrigger)
  let entryStoreDate = trapTrigger.dateStored.parse("yyyy-MM-dd'T'HH:mm:sszzz")
  let trapInterval = traps["trap"][trap].getTable()["every"].getStr().parseDuration()
  if now() - entryStoreDate > trapInterval:
    return true
  else:
    return false

proc loadTrapDbs(traps: TomlValueRef) =
  ## creates a db file for every configured trap
  for k, v in traps["trap"].getTable:
    dbs[k] = newFlatDb(genName(k))
    discard dbs[k].load()

proc trapKnown*(toml: TomlValueRef, trap: string): bool =
  ## return true if a trap with this name exists
  return toml["trap"].existsKey(trap)

proc triggerTrap*(toml: TomlValueRef, trapTrigger: var TrapTrigger) =
  ## triggers the trap
  # echo "IN TRIGGER TRAP"
  trapTrigger.dateStored = $now()
  discard dbs[trapTrigger.trap].append (%* trapTrigger)
  echo isAlarm(trapTrigger.trap)

proc checkTraps*(): Future[void] {.async.} =
  while true:
    for trap in dbs.keys():
      # echo "CHECKING TRAP: ", trap
      # echo trap, ": ", 
      currentState[trap] = %* trap.isAlarm()
    echo $currentState
    await sleepAsync(1_000)

modmtraps.initProc = proc(obj: Pepperd, params: string): Future[JsonNode] {.async, closure.} =
  echo "trap init"
  traps = parseToml.parseFile(trapconfig)
  traps.loadTrapDbs()
  asyncCheck checkTraps()

  # createDir(getAppDir() / "www/slaves/linux")
  # createDir(getAppDir() / "www/slaves/windows")
  # createDir(getAppDir() / "www/slaves/macos")

modmtraps.boundCommands["trapinfo"] = proc(obj: Pepperd, params: string): Future[JsonNode] {.async, closure.} =
  #   # echo "www COMMAND CALLED"
  # result = %* {}
  return currentState
  # return %* {"outp": "pong"}

# modmtraps.slaveConnects = proc(obj: Pepperd, client: Client): Future[void] {.async, closure.} =
#   echo "WWW CLIENT CONNECTS:", client.peerAddr #, repr client
#   ## check slave for version
#   ## if version is old
#   ##  initialize update process
#   return

# modmtraps.slaveDisconnects = proc(obj: Pepperd, client: Client): Future[void] {.async, closure.} =
#   echo "WWW CLIENT DISCONNECTS:", client.peerAddr #repr client
#   return



modmtraps.httpCallback = proc(obj: Pepperd, request: Request): Future[bool] {.async, closure.} =
  ## returns true if the http request was handled by this callback  
  echo "TRAP TRIGGER"
  if not ($request.url.path).startsWith("/trap"):
    return false 
  var trapTrigger: TrapTrigger
  try:
    trapTrigger = request.body.parseJson().to(TrapTrigger)
  except:
    echo "[mtraps] could not parse json"
    await request.respond(Http400, "invalid json" )   
    return
  if not traps.trapKnown(trapTrigger.trap):
    echo "[mtraps] unknown trap: ", trapTrigger.trap
    await request.respond(Http400, "unknown trap" )
    return
  traps.triggerTrap(trapTrigger)
  
  await request.respond(Http200, "bum" ) 
  # case $request.url.path
  # of "/www/linux/latest/pepperslave":
  #   let slavePath = getLatest() / "pepperslave"
  #   if not fileExists(slavePath): 
  #     await request.respond(Http404, "not found")
  #     return
  #   var  slaveBinary = readFile(slavePath)
  #   await request.respond(Http200, slaveBinary )

  # of "/www/slaves/windows/latest":
  #   await request.respond(Http200, "latest windows")
  # else:
  #   return false
  # return true

# modmtraps.httpAdminCallback = proc(obj: Pepperd, request: Request): Future[bool] {.async, closure.} =
#   ## returns true if the http request was handled by this callback
#   if ($request.url.path).startsWith("/www"):
#     await request.respond(Http200, "www")
#     return true
#   else:
#     return false
