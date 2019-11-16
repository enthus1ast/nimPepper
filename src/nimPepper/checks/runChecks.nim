import parsetoml
import ../lib/parseTomlDates
import tables, json, os, strtabs

let checks = parsetoml.parseFile( "/home/david/nimPepper/src/nimPepper/config/masterchecks.toml" )  #getAppDir() / "../config/masterchecks.toml")
let commands = parsetoml.parseFile(getAppDir() / "../config/commands.toml")

proc newStringTable(tomlTabRef: TomlTableRef): StringTableRef =
  result = newStringTable()
  for k, v in tomlTabRef:
    result[k] = v.getStr()

for name, checkConfig in checks.getTable():
  echo "running: ", name
  var check = commands[checkConfig["check"].getStr()]
  echo check["binary"]
  let params = check["params"].getStr() % checkConfig.getTable().newStringTable
  echo execSHellCmd(getAppDir() / check["binary"].getStr() & " " & params ) #& " " , params % [])
  echo "==========="
