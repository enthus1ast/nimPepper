# import ../../typesModuleSlave
import ../../pepperdImports
import ../../typesPepperd
import ../../moduleLoader
import ../../messages
import ../../netfuncs
import strutils
import ../../pepperdFuncs

# var module* {.exportc.} = newSlaveModule("defaults")
var modmping* {.exportc.} = newMasterModule("defaults")

proc pingClients(pepperd: Pepperd): Future[void] {.async.} =
  while true:
    for client in pepperd.clients.values:
      echo "pinging: ", client.name
      var msg = MsgReq()
      msg.command = "defaults.ping"
      # echo "send to: ", $client
      await pepperd.send(client, msg)
      try:
        if not await withTimeout(pepperd.recv(client), 5000):
          raise
      except:
        await pepperd.handleLostClient(client.request, client.ws)
    await sleepAsync(2250)


modmping.boundCommands["ping"] = proc(obj: Pepperd, params: string): Future[JsonNode] {.async, closure.} =
  return %* {"outp": "pong"}

# modmping.boundCommands["substitutions"] = proc(obj: Pepperd, params: string): Future[JsonNode] {.async, closure.} =
#   var res = ""
#   for key, val in obj.substitutionContext:
#     res.add "$#: $# \n" % [key ,val]
#   return %* {"outp": res}
