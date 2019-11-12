# import ../../typesModuleSlave
import ../../lib/pepperdImports
import ../../lib/typesPepperd
import ../../lib/moduleLoader
import ../../lib/messages
import ../../lib/netfuncs
# import ../../lib/pepperdFuncs
import asyncudp
import multicast
import strutils

import sharedmasterfind

var modmmasterfind* {.exportc.} = newMasterModule("masterfind")

proc serveMulticastAnswerer(obj: Pepperd): Future[void] {.async.} =
  var socket = newAsyncSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
  if not socket.getFd.joinGroup(parseIpAddress(multicastGroup)):
    echo "[masterfind] could not join multicast group"
    return
  else:
    echo "[masterfind] joined multicast group"
  socket.bindAddr(Port(multicastPort))
  while true:
    var req = await socket.recvFrom(msgLen)
    echo req
    if req.data.strip() == magicReq:
      echo "[masterfind] got " & magicReq & " from: ", req.address, ":", req.port
      let res = "$# $# $#" % [
        magicRes, 
        obj.configPepperd.getSectionValue("master", "httpport"),
        obj.configPepperd.getSectionValue("master", "publicKey"),
      ]
      await socket.sendTo(req.address, req.port, res)

modmmasterfind.initProc = proc(obj: Pepperd, params: string): Future[JsonNode] {.async, closure.} =
  asyncCheck obj.serveMulticastAnswerer()

# modmping.boundCommands["ping"] = proc(obj: Pepperd, params: string): Future[JsonNode] {.async, closure.} =
#   return %* {"outp": "pong"}
