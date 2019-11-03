import parseopt, os, strscans, strutils, base64, terminal, sequtils, strformat
import lib/pepperdImports
import lib/typesPepperd
import lib/keymanager
import lib/messages
import lib/pepperSlaveOnline
import lib/matcher
import pepperd
import msgpack4nim
# import cligen

iterator call(targets, commands, commandParams: string): MsgAdminRes =
  let ws = waitFor newAsyncWebsocketClient("localhost", Port(9999),
  path = "/", protocols = @["pepperadmin"])

  var req = MsgAdminReq()
  req.targets = targets
  req.commands = commands
  req.commandParams = commandParams
  var reqs = pack(req)
  waitFor ws.sendBinary(reqs)
  
  var 
    opcode: Opcode
    data: string
  while true:
    try:
      (opcode, data) = waitFor ws.readData()
    except:
      # echo getCurrentExceptionMsg()
      break
    if opcode != Binary: 
      # echo "not binary"
      continue
    var adminRes = MsgAdminRes()
    unpack(data, adminRes)
    yield adminRes
  waitFor ws.close()

proc getParamSeq(): seq[string] =
  for idx in 1..paramCount():
    result.add paramStr(idx)

proc getParamStr(): string =
  return getParamSeq().join(" ")
echo getParamSeq()
echo getParamStr()
var pepd = newPepperd()
var params = initOptParser()
const HELP = """
SOME HELP
"""
var regs: seq[(string, string)] = @[]

proc `$`(slaves: seq[SlaveForOutput]): string = 
  for slave in slaves:
    result.add "\t\"" & slave.slaveName & "\"\t" & slave.publicKey.encode() & "\n"

proc print(clientInfo: ClientInfo) =
  if clientInfo.online:
    setForegroundColor(fgGreen)
  else:
    setForegroundColor(fgRed)
  echo fmt"{clientInfo.name} ({clientInfo.ip}) {clientInfo.publicKey}"
  setForegroundColor(fgDefault)

proc help() = 
  echo HELP
  echo "Valid Commands:"
  echo "###############"
  for reg in regs:
    echo reg[0], "\t#", reg[1]
  # echo regs.join("\n")

var matches = newStringTable()

template chk(params: OptParser, pattern: string, doc: string = "", results: StringTableRef ): bool = 
  regs.add( (pattern, doc) ) 
  match(params, pattern, results)

if chk(params, "keys list", "list all keys", matches):
  echo "show keys"
  setForegroundColor(fgGreen)
  echo "accepted:"
  echo $pepd.getAccepted()
  setForegroundColor(fgRed)
  echo "unaccepted:"
  echo $pepd.getUnaccepted()  
  setForegroundColor(fgDefault)

elif chk(params, "keys list accepted", "list accepted keys", matches):
  setForegroundColor(fgGreen)
  echo "accepted"
  echo $pepd.getAccepted()
  setForegroundColor(fgDefault)

elif chk(params, "keys list unaccepted", "lists all unaccepted keys", matches):
  setForegroundColor(fgRed)
  echo "unaccepted"
  echo $pepd.getUnaccepted()
  setForegroundColor(fgDefault)

elif chk(params, "keys accept {slavename}", "accept the key by its name", matches):
  setForegroundColor(fgGreen)  
  echo "ACCEPT: ", matches["slavename"] 
  pepd.accept(matches["slavename"])
  setForegroundColor(fgDefault)

elif chk(params, "keys unaccept {slavename}", "unaccept the key by its name, leaves slave configuration untouched", matches):
  setForegroundColor(fgRed)
  echo "UNACCEPT: ", matches["slavename"]
  pepd.unacept(matches["slavename"])
  setForegroundColor(fgDefault)

elif chk(params, "keys clear unaccepted", "removes all unaccepted keys", matches):
  pepd.clearUnaccepted()
  setForegroundColor(fgRed)    
  echo "cleared all UNACCEPTED"
  setForegroundColor(fgDefault)

elif chk(params, "call {targets} {command} {params}", "call commands on hosts eg: call \"targetselector\" \"commands to send\" ", matches):
  for res in call(matches["targets"], matches["command"], matches["params"]):
    setForegroundColor(fgGreen)
    echo "#################"
    echo res.target
    setForegroundColor(fgDefault)
    var js = parseJson(res.output)
    if js.contains("outp"):
      echo js["outp"].getStr()
      js.delete("outp") # = %* ""
    echo js.pretty
    # echo parseJson(res.output)["outp"].getStr()

elif chk(params, "slaves online", "list all slaves and if theyre online or not", matches):
  for adminRes in call("*", "master.slaveinfo", ""):
    var clientInfo = ClientInfo()
    unpack(adminRes.output, clientInfo)
    print clientInfo  

elif chk(params, "slaves online interactive", "starts an interactive overview of all slaves and if theire online", matches):
  var so = newSlaveOnline()
  asyncCheck so.pepperSlaveOnlineMain()

  while true:
    var newClients: seq[ClientInfo] = @[]
    for adminRes in call("*", "master.slaveinfo", ""):
      var clientInfo = ClientInfo()
      unpack(adminRes.output, clientInfo)
      newClients.add clientInfo
    so.clients = newClients
    so.resetLastRefresh()
    waitFor sleepAsync(5000)

elif chk(params, "help", "print this help", matches):
  help()
else:
  echo "Unknown command given!"
  help()