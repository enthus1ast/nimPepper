import messages
import pepperdImports
import typesPepperd
import logger
import hashes
import netfuncs
import keymanager
import createenv

proc hash(ws: AsyncWebSocket): Hash = 
  var h: Hash = 0
  h = h !& hash(ws.sock.getFd)
  # h = h !& hash
  return h

proc newPepperd*(): Pepperd = 
  result = Pepperd()
  result.pathPepperd = getCurrentDir()
  result.createEnvironment()
  result.configPepperd = loadConfig(result.pathConfigPepperd)
  result.httpserver = newAsyncHttpServer()

proc httpCallback(pepperd: Pepperd, request: Request): Future[void] {.async.} =
  await request.respond(Http400, "http not implemented")
  request.client.close()

proc handleLostClient(pepperd: Pepperd, request: Request, ws: AsyncWebSocket): Future[void] {.async.} =
  info("[pepperd] lost client: ", request.client.getPeerAddr)
  if pepperd.clients.contains(ws):
    debug("[pepperd] remove ws from clients table")
    pepperd.clients.del(ws)
  if not request.client.isClosed():
    request.client.close()

# proc authenticate(pepped: Pepperd, request: Request, ws: AsyncWebSocket): Client =
#   ## when the connection authenticated, create a client, add it to the
#   ## clients list and returns the client, if not raise exception

proc send(pepperd: Pepperd, client: Client, msg: MessageConcept): Future[void] {.async.} =
  let myPrivatKey = pepperd.configPepperd.getSectionValue("master", "privateKey").decode().toPrivateKey
  let myPublicKey = pepperd.configPepperd.getSectionValue("master", "publicKey").decode().toPublicKey
  let receiverPublicKey =  client.publicKey #pepperd.configSlave.getSectionValue("master", "publicKey").decode().toPublicKey  
  let envelope = packEnvelope(msg)
  var firstLevel: FirstLevel
  if not packToFirstLevel(
      myPrivatKey,
      myPublicKey,
      receiverPublicKey,
      pack(envelope),
      firstLevel
      ):
    echo "could not packToFirstLevel"
    return
  # echo firstLevel
  var firstLevelMsg = pack(firstLevel)
  echo $firstLevelMsg
  await sendBinary(client.ws, firstLevelMsg)  

proc recvData(pepperd: Pepperd, client: Client): Future[(Opcode, string)] {.async.} = 
  ## when everything is good returns true, else false is returned.
  ## when the client disconnects during recv. the client is removed from clients table
  var 
    opcode: Opcode
    data: string
  try:
    (opcode, data) = await client.ws.readData()
  except:
    debug("[pepperd] ws connection interrupted: ", client.request.client.getPeerAddr)
    await pepperd.handleLostClient(client.request, client.ws)
    raise
  debug("[pepperd] got ws frame from: $# opcode: $# \nframe:\n$#" % [
      $client.peerAddr,
      $opcode,
      data
  ])  
  case opcode
  of Close:
    debug("[pepperd] ws connection closed: ", client.peerAddr)
    await pepperd.handleLostClient(client.request, client.ws)
    raise 
  of Text:
    debug("[pepperd] 'text' ws not implemented: ", client.peerAddr)
  of Binary:
    return (opcode, data)
  of Ping:
    debug("[pepperd] 'ping' ws not implemented: ", client.peerAddr)
    raise
  of Pong:
    debug("[pepperd] 'pong' ws not implemented: ", client.peerAddr)
    raise
  of Cont:
    debug("[pepperd] 'cont' ws not implemented: ", client.peerAddr)  
    raise

proc recv(pepperd: Pepperd, client: Client): Future[tuple[firstLevel: FirstLevel, envelope: MessageEnvelope]] {.async.} =
  var 
    opcode: Opcode
    data: string
  try:
    (opcode, data) = await pepperd.recvData(client)
  except: 
    raise
  let myPrivateKey = pepperd.configPepperd.getSectionValue("master", "privateKey").decode().toPrivateKey
  if not unpack(myPrivateKey, data, result.firstLevel, result.envelope):
    debug("[pepperd] could not unpack the whole message")
    raise
  

proc handleWsMessage(pepperd: Pepperd, oclient: Client): Future[void] {.async.} =
  debug("[pepperd] in handle ws client")
  var client = oclient
  client.peerAddr = client.request.client.getPeerAddr

  # let myPrivateKey = pepperd.configPepperd.getSectionValue("master", "privateKey").decode().toPrivateKey
  # var envelope: MessageEnvelope
  # var firstLevel: FirstLevel
  # if not unpack(myPrivateKey, data, firstLevel, envelope):
  #   debug("[pepperd] could not unpack the whole message")
  #   return
  var 
    firstLevel: FirstLevel
    envelope: MessageEnvelope 
  try:
    (firstLevel, envelope) = await pepperd.recv(client)
  except:
    return    
  
  client.publicKey = firstLevel.senderPublicKey

  if not pepperd.clients.contains(client.ws):
    client.publicKey = firstLevel.senderPublicKey
    pepperd.clients.add(
      client.ws,
      client
    )
  else:
    echo "ws known"

  debug "Got: ", envelope.messageType
  case envelope.messageType
  of MessageType.MsgReq:
    echo "got a request"
    var req: MsgReq
    unpack(envelope.msg, req)
    echo req
  of MessageType.MsgRes:
    echo "got a response"
    var res: MsgRes
    unpack(envelope.msg, res)
    echo res
    # if res.command == "ping":
  of MessageType.MsgUntrusted:
    echo "client does not trust us"
  # extractMessage(envelope)
  # echo foo
  # echo msg
  ## vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
  ## maybe check if client with this publicKey is known
  ## ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  # let msgMap = envelope.msg.toAny
  # echo msgMap
  # if pepperdfirstLevel.senderPublicKey.
  # case envelope.messageType
  # of MessageType.MsgLog:
  #   await masterHandleLog()
  # else:
  #   echo "could not handle message"


proc wsCallback(pepperd: Pepperd, request: Request, ws: AsyncWebSocket): Future[void] {.async.} =
  var client = Client(
        ws: ws, 
        request: request,
      )
  # while true:
    # var 
    #   opcode: Opcode
    #   data: string
    # try:
    #   (opcode, data) = await pepperd.recvData(client)
    # except: 
    #   break
  asyncCheck pepperd.handleWsMessage(client)

proc httpBaseCallback(pepperd: Pepperd, request: Request): Future[void] {.async.} =
  let (ws, error) = await verifyWebsocketRequest(request, "pepper")
  if ws.isNil:
    debug("[pepperd] http request from: ", request.client.getPeerAddr)
    await httpCallback(pepperd, request)
  else:
    debug("[pepperd] ws negotiation from: ", request.client.getPeerAddr)
    await wsCallback(pepperd, request, ws)

proc run(pepperd: Pepperd): Future[void] {.async.} = 
  let port = Port(pepperd.configPepperd.getSectionValue("master", "httpport").parseInt.Port)
  info("[pepperd] binding http to: " & $port)
  await pepperd.httpserver.serve(
    port,
    proc (request: Request): Future[void] = httpBaseCallback(pepperd, request)
  )

proc debugSendToAll(pepperd: Pepperd): Future[void] {.async.} =
  while true:
    for client in pepperd.clients.values:
      var msg = MsgReq()
      msg.command = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAa"
      echo "send to: ", $client
      await pepperd.send(client, msg)
    await sleepAsync(2250)

when isMainModule:
  var pepperd = newPepperd()
  # asyncCheck pepperd.debugSendToAll()
  waitFor pepperd.run()