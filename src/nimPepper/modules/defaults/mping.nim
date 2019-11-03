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
var modmping* {.exportc.} = newMasterModule("defaults")

proc pingClients(pepperd: Pepperd): Future[void] {.async.} =
  while true:
    for client in pepperd.clients.values:
      echo "pinging: ", client.name
      var msg = MsgReq()
      msg.command = "defaults.ping"
      # msg.params = $getTime().toUnix()
      # echo "send to: ", $client
      await pepperd.send(client, msg)
      try:
        if not await withTimeout(pepperd.recv(client), 5000):
          raise
      except:
        await pepperd.handleLostClient(client.request, client.ws)
    await sleepAsync(2250)

modmping.initProc = proc(obj: Pepperd, params: string): Future[JsonNode] {.async, closure.} =
  asyncCheck obj.pingClients

modmping.boundCommands["ping"] = proc(obj: Pepperd, params: string): Future[JsonNode] {.async, closure.} =
  return %* {"outp": "pong"}
