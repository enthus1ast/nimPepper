# import ../../typesModuleSlave
import ../../lib/pepperdImports
import ../../lib/typesPepperd
import ../../lib/moduleLoader
import ../../lib/messages
import ../../lib/netfuncs
import ../../lib/pepperdFuncs
import strutils
import times

const 
  PING_EVERY = 10_000 # pings nodes every x
  PING_TIMEOUT = 10_000 # waits x long for answer

var modmping* {.exportc.} = newMasterModule("defaults")

proc pingClients(pepperd: Pepperd): Future[void] {.async.} =
  while true:
    for client in pepperd.clients.values:
      echo "pinging: ", client.name
      var msg = MsgReq()
      msg.command = "defaults.ping"
      await pepperd.send(client, msg)
      try:
        if not await withTimeout(pepperd.recv(client), PING_TIMEOUT):
          raise
      except:
        await pepperd.handleLostClient(client.request, client.ws)
    await sleepAsync(PING_EVERY)

modmping.initProc = proc(obj: Pepperd, params: string): Future[JsonNode] {.async, closure.} =
  asyncCheck obj.pingClients

modmping.boundCommands["ping"] = proc(obj: Pepperd, params: string): Future[JsonNode] {.async, closure.} =
  return %* {"outp": "pong"}