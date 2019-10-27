import parseopt, os, strscans, strutils, base64, terminal, sequtils, strformat
import pepperdImports, typesPepperd, pepperd, keymanager, messages, msgpack4nim
import pepperSlaveOnline
import cligen

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

var pepd = newPepperd()
let params = getParamStr()
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

var
  ## vars that are set by the command line.
  slaveName: string
  targets: string
  command: string
  commandParams: string

template chk(params, pattern: string, doc: string = "", results: untyped = void ): bool = 
  regs.add( (pattern, doc) ) 
  scanf(params, pattern, results)

if chk(params, "keys list$.", "list all keys"):
  echo "show keys"
  setForegroundColor(fgGreen)
  echo "accepted:"
  echo $pepd.getAccepted()
  setForegroundColor(fgRed)
  echo "unaccepted:"
  echo $pepd.getUnaccepted()  
  setForegroundColor(fgDefault)

elif chk(params, "keys list accepted$.", "list accepted keys"):
  setForegroundColor(fgGreen)
  echo "accepted"
  echo $pepd.getAccepted()
  setForegroundColor(fgDefault)

elif chk(params, "keys list unaccepted$.", "lists all unaccepted keys"):
  setForegroundColor(fgRed)
  echo "unaccepted"
  echo $pepd.getUnaccepted()
  setForegroundColor(fgDefault)

elif chk(params, "keys accept $w", "accept the key by its name", slaveName):
  setForegroundColor(fgGreen)  
  echo "ACCEPT: ", slaveName
  pepd.accept(slaveName)
  setForegroundColor(fgDefault)

elif chk(params, "keys unaccept $w", "unaccept the key by its name, leaves slave configuration untouched", slaveName):
  setForegroundColor(fgRed)    
  echo "UNACCEPT: ", slaveName
  pepd.unacept(slaveName)
  setForegroundColor(fgDefault)

elif chk(params, "keys clear unaccepted$.", "removes all unaccepted keys"):
  pepd.clearUnaccepted()
  setForegroundColor(fgRed)    
  echo "cleared all UNACCEPTED"
  setForegroundColor(fgDefault)

elif chk(params, "call", "call commands on hosts eg: call \"targetselector\" \"commands to send\" "):
  var p = initOptParser()
  var cmds = toSeq(p.getopt)
  targets = cmds[1].key
  command = cmds[2].key
  
  if cmds.len >= 4:
    commandParams = cmds[3].key
  else:
    commandParams = ""

  for res in call(targets, command, commandParams):
    setForegroundColor(fgGreen)
    echo "#################"
    echo res.target
    setForegroundColor(fgDefault)
    echo parseJson(res.output)["outp"].getStr()

elif chk(params, "slaves online$.", "list all slaves and if theyre online or not"):
  for adminRes in call("*", "master.slaveinfo", ""):
    var clientInfo = ClientInfo()
    unpack(adminRes.output, clientInfo)
    print clientInfo  

elif chk(params, "slaves online interactive$.", "starts an interactive overview of all slaves and if theire online"):
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
    # so.clients =   #master.slaveinfo
    waitFor sleepAsync(5000)

elif chk(params, "help", "print this help"):
  help()
else:
  echo "Unknown command given!"
  help()