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
import msgpack4nim

let trapconfig = getAppDir() / "/config/mastertraps.toml"
let trapfolder = getAppDir() / "/traps/"

type
  Dbs = Table[string, FlatDb]

var 
  dbs: Dbs
  modmtraps* {.exportc.} = newMasterModule("traps")
  traps: TomlValueRef
  currentState: JsonNode = %* {}

proc genName(trap: string): string =
  trapfolder / trap & ".jsonl"

proc isAlarm(trap: string): bool =
  ## checks trap if is in alarming state
  let entry = dbs[trap].queryOneReverse(equal("trap", trap))
  if entry.isNil:
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

proc trapKnown*(traps: TomlValueRef, trap: string): bool =
  ## return true if a trap with this name exists
  return traps["trap"].existsKey(trap)

proc triggerTrap*(dbs: Dbs, trapTrigger: var TrapTrigger) =
  ## triggers the trap
  trapTrigger.dateStored = $now()
  discard dbs[trapTrigger.trap].append (%* trapTrigger)

proc checkTraps*(): Future[void] {.async.} =
  while true:
    for trap in dbs.keys():
      currentState[trap] = %* trap.isAlarm()
    await sleepAsync(1_000)

proc info*(traps: TomlValueRef) =
  discard
  echo "[mtraps] Active Traps:"
  for trap, conf in traps["trap"].getTable():
    echo "[mtraps] $trap -> $every" % @[
      "trap", trap,
      "every", conf["every"].getStr()
    ]

modmtraps.initProc = proc(obj: Pepperd, params: string): Future[JsonNode] {.async, closure.} =
  echo "trap init"
  createDir(getAppDir() / "traps")
  if not fileExists(trapconfig):
    echo "[mtraps] not found: ", trapconfig
    return
  traps = parseToml.parseFile(trapconfig)
  traps.loadTrapDbs()
  traps.info()
  asyncCheck checkTraps()

modmtraps.boundCommands["trapinfo"] = proc(obj: Pepperd, params: string): Future[JsonNode] {.async, closure.} =
  return currentState

modmtraps.httpCallback = proc(obj: Pepperd, request: Request): Future[bool] {.async, closure.} =
  ## returns true if the http request was handled by this callback  
  if not ($request.url.path).startsWith("/trap"):
    return false 
  var trapTrigger: TrapTrigger
  ## TODO unseal does not really fit atm. Do it later
  # var firstLevel: FirstLevel
  # var envelope: MessageEnvelope
  # if not unseal(obj.myPrivateKey(), request.body, firstLevel, envelope):
  #   await request.respond(Http400, "crypt failure sorry" )
  #   return
  try:
    # trapTrigger = firstLevel.raw.parseJson().to(TrapTrigger)
    request.body.unpack(trapTrigger)
  except:
    echo "[mtraps] could not parse json"
    await request.respond(Http400, "invalid json" )   
    return
  if not traps.trapKnown(trapTrigger.trap):
    echo "[mtraps] unknown trap: ", trapTrigger.trap
    await request.respond(Http400, "unknown trap" )
    return
  dbs.triggerTrap(trapTrigger)
  await request.respond(Http200, "bum" ) 