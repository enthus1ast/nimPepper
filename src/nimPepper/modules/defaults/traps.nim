import parsetoml, json, tables, os, ospaths, times
import parseTomlDates

let trapconfig = getAppDir() / "../../traps/mastertraps.toml"
let trapfolder = getAppDir() / "../../traps/"

proc genName(trap: string): string =
  trapfolder / trap & ".jsonl"

let cmds = parseToml.parseFile(trapconfig)
for k, v in cmds["trap"].getTable:
  echo k
  if not existsFile(genName(k)):
    open(genName(k), fmWrite).close()

# echo now() + initDuration(hours = 1)


proc triggerTrap(trap: string, data: string, good, bad: bool) =
  var fh = open(genName(trap), fmAppend)
  fh.writeLine($ %* {
    "time": $now(),
    "good": good,
    "bad": bad,
    "data": data
  })
  fh.close()

echo cmds["trap"]["test123"].getTable() # ["test123"]["every"]) #.getTable() # ["every"].getStr()

# proc checkTraps(): seq[string] = 
#   for k, v in cmds["trap"].getTable:
#     echo repr v["every"].getStr() # .getTable() # ["every"]
#     # echo cmds["trap"][k]["every"].getStr()
#     # echo k ,v.getTable 
#     # echo v.getTable["every"].getStr() # ["every"]
#     # echo repr v["every"].getStr()
#     # echo v["every"] #).parseDuration()

# when isMainModule:
#   discard
#   echo checkTraps()
#   # triggerTrap("test123", "some data", true, false)
