import messages
import pepperdImports
import typesPepperd
import logger
import hashes
import netfuncs
import keymanager
import createenv

proc myPublicKey(pepperd: Pepperd): PublicKey =
  return pepperd.configPepperd.getSectionValue("master", "publicKey").decode().toPublicKey

proc myPrivateKey(pepperd: Pepperd): PrivateKey =
  return pepperd.configPepperd.getSectionValue("master", "privateKey").decode().toPrivateKey


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
  result.adminhttpserver = newAsyncHttpServer()

proc httpCallback(pepperd: Pepperd, request: Request): Future[void] {.async.} =
  await request.respond(Http400, "http not implemented")
  request.client.close()

proc adminHttpCallback(pepperd: Pepperd, request: Request): Future[void] {.async.} =
  await request.respond(Http400, "admin http not implemented")
  request.client.close()

proc handleLostClient(pepperd: Pepperd, request: Request, ws: AsyncWebSocket): Future[void] {.async.} =
  info("[pepperd] lost client: ", request.client.getPeerAddr)
  if pepperd.clients.contains(ws):
    debug("[pepperd] remove ws from clients table")
    pepperd.clients.del(ws)
  if not request.client.isClosed():
    request.client.close()

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
  var firstLevelMsg = pack(firstLevel)
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
  # debug("[pepperd] got ws frame from: $# opcode: $# \nframe:\n$#" % [
  #     $client.peerAddr,
  #     $opcode,
  #     data
  # ])  
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

proc authenticate(pepperd: Pepperd, request: Request, ws: AsyncWebSocket): Future[Client] {.async.} =
  ## when the connection authenticated, create a client, add it to the
  ## clients list and returns the client, if not raise exception
  result = Client(
    ws: ws, 
    request: request,
  )
  var 
    firstLevel: FirstLevel
    envelope: MessageEnvelope 
  try:
    (firstLevel, envelope) = await pepperd.recv(result)
  except:
    echo "[authenticate] failure to recv in authenticate"
    raise
  result.publicKey = firstLevel.senderPublicKey
  var req: MsgReq
  case envelope.messageType
  of MessageType.MsgReq:
    echo "got a request"
    try:
      unpack(envelope.msg, req)
    except:
      echo "unpack failed"
      raise
  else:
    echo "[authenticate] not a MessageType.MsgReq"
    raise

  if req.senderPublicKey != firstLevel.senderPublicKey:
    echo "error senderPublicKey in packed msg is different that in unencrypted firstLeve"
    raise

  if req.senderName == "":
    echo "erro senderName == \"\""
    raise

  result.name = req.senderName

  echo "create files:"
  if pepperd.isUnaccepted(req.senderName, req.senderPublicKey.toString):
    echo "client is unaccepted, closing"
    await result.ws.close()
    raise
  elif pepperd.isAccepted(req.senderName, req.senderPublicKey.toString):
    echo "[+] client is accepted, proceed"

    ## Adding client to the clients table
    if not pepperd.clients.contains(result.ws):
      pepperd.clients.add(
        result.ws,
        result
      )
    else:
      echo "ws known"

    return result
  else:
    echo "client is unknown yet, create an unnacepted file."
    pepperd.createUnaccepted(req.senderName, req.senderPublicKey.toString)
    raise
  echo "[BUG] reached the end... (not possible....)"

proc handleWsMessage(pepperd: Pepperd, oclient: Client): Future[void] {.async.} =
  debug("[pepperd] in handle ws client")
  # var client = oclient
  # client.peerAddr = client.request.client.getPeerAddr

  # var 
  #   firstLevel: FirstLevel
  #   envelope: MessageEnvelope 
  # try:
  #   (firstLevel, envelope) = await pepperd.recv(client)
  # except:
  #   return    
  
  # client.publicKey = firstLevel.senderPublicKey

  # if not pepperd.clients.contains(client.ws):
  #   client.publicKey = firstLevel.senderPublicKey
  #   pepperd.clients.add(
  #     client.ws,
  #     client
  #   )
  # else:
  #   echo "ws known"

  # debug "Got: ", envelope.messageType
  # case envelope.messageType
  # of MessageType.MsgReq:
  #   echo "got a request"
  #   var req: MsgReq
  #   unpack(envelope.msg, req)
  #   echo req
  # of MessageType.MsgRes:
  #   echo "got a response"
  #   var res: MsgRes
  #   unpack(envelope.msg, res)
  #   echo res
  #   # if res.command == "ping":
  # of MessageType.MsgUntrusted:
  #   echo "client does not trust us"


proc wsCallback(pepperd: Pepperd, request: Request, ws: AsyncWebSocket): Future[void] {.async.} =
  var client: Client
  try:  
    client = await pepperd.authenticate(request, ws)
  except:
    echo "authenticate failed somehow"
    return

  # while true:
    # var 
    #   opcode: Opcode
    #   data: string
    # try:
    #   (opcode, data) = await pepperd.recvData(client)
    # except: 
    #   break
  asyncCheck pepperd.handleWsMessage(client)

iterator targets(pepperd: Pepperd, targets: string): Client =
  echo "dummy iterator targets"
  # echo repr pepperd.clients
  var pattern = targets.glob()
  for client in pepperd.clients.values:
    if client.name.matches(pattern):
      yield client

proc adminWsCallback(pepperd: Pepperd, request: Request, ws: AsyncWebSocket): Future[void] {.async.} =
  var adminClient = Client(
    request: request,
    ws: ws
  )
  var 
    opcode: Opcode
    data: string
  try:
    (opcode, data) = await pepperd.recvData(adminClient)
  except:
    echo getCurrentExceptionMsg()
    return
  
  echo "get admin data:", data
  var adminReq = MsgAdminReq()
  unpack(data, adminReq)

  for target in pepperd.targets(adminReq.targets):
    # echo send to client
    echo target.name

    var msgReq = MsgReq()
    msgReq.command = adminReq.commands
    msgReq.params = adminReq.commandParams
    msgReq.senderPublicKey = pepperd.myPublicKey()

    try:
      await pepperd.send(target, msgReq)
    except:
      echo getCurrentExceptionMsg()
      continue
      


    var 
      firstLevel: FirstLevel
      envelope: MessageEnvelope 
    try:
      (firstLevel, envelope) = await pepperd.recv(target)
    except:
      echo getCurrentExceptionMsg()
      echo "[pepeprd] failure to recv in in call to: ", target
      # raise
      continue

    var res: MsgRes
    unpack(envelope.msg, res)


    var adminRes = MsgAdminRes()
    adminRes.target = $target.name
    adminRes.output = res.output
    let adminResStr = pack(adminRes)
    # echo "adminResStr:", adminResStr
    # echo "adminResStL:", adminResStr.len
    # echo adminResStr.encode

    # var adminRes2 = MsgAdminRes()
    # unpack(adminResStr, adminRes2)
    # echo adminRes2
    echo "going to send:", adminResStr
    try:
      await adminClient.ws.sendBinary(adminResStr)
    except:
      echo getCurrentExceptionMsg()
      continue
    echo "sending done..."
  # await sleepAsync(2000)
  echo "closing"
  await adminClient.ws.close()
  
  # var client: Client
  # try:  
  #   client = await pepperd.authenticate(request, ws)
  # except:
  #   echo "authenticate failed somehow"
  #   return
  # while true:
    # var 
    #   opcode: Opcode
    #   data: string
    # try:
    #   (opcode, data) = await pepperd.recvData(client)
    # except: 
    #   break
  # asyncCheck pepperd.handleWsMessage(client)

proc httpBaseCallback(pepperd: Pepperd, request: Request): Future[void] {.async.} =
  let (ws, error) = await verifyWebsocketRequest(request, "pepper")
  if ws.isNil:
    debug("[pepperd] http request from: ", request.client.getPeerAddr)
    await httpCallback(pepperd, request)
  else:
    debug("[pepperd] ws negotiation from: ", request.client.getPeerAddr)
    await wsCallback(pepperd, request, ws)

proc adminHttpBaseCallback(pepperd: Pepperd, request: Request): Future[void] {.async.} =
  let (ws, error) = await verifyWebsocketRequest(request, "pepperadmin")
  if ws.isNil:
    debug("[pepperd] admin http request from: ", request.client.getPeerAddr)
    await adminHttpCallback(pepperd, request)
  else:
    debug("[pepperd] admin ws negotiation from: ", request.client.getPeerAddr)
    await adminWsCallback(pepperd, request, ws)


proc run(pepperd: Pepperd): Future[void] {.async.} = 
  let port = Port(pepperd.configPepperd.getSectionValue("master", "httpport").parseInt.Port)
  let adminport = Port(pepperd.configPepperd.getSectionValue("master", "adminhttpport").parseInt.Port)
  info("[pepperd] binding http to: " & $port)
  info("[pepperd] binding admin http to: " & $adminport)
  asyncCheck pepperd.adminhttpserver.serve(
    adminport,
    proc (request: Request): Future[void] = adminHttpBaseCallback(pepperd, request),
    address = "127.0.0.1"
  )
  await pepperd.httpserver.serve(
    port,
    proc (request: Request): Future[void] = httpBaseCallback(pepperd, request)
  )

# proc debugSendToAll(pepperd: Pepperd): Future[void] {.async.} =
#   while true:
#     for client in pepperd.clients.values:
#       var msg = MsgReq()
#       msg.command = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAa"
#       echo "send to: ", $client
#       await pepperd.send(client, msg)
#     await sleepAsync(2250)

when isMainModule:
  var pepperd = newPepperd()
  # asyncCheck pepperd.debugSendToAll()
  waitFor pepperd.run()