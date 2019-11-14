import lib/messages
import lib/pepperdImports
import lib/typesPepperd
import lib/logger
import lib/netfuncs
import lib/keymanager
import lib/createenv
import lib/pepperdFuncs
import modules/masterModules
import options
import hashes

proc myPublicKey(pepperd: Pepperd): PublicKey =
  return pepperd.configPepperd.getSectionValue("master", "publicKey").decode().toPublicKey

proc myPrivateKey(pepperd: Pepperd): PrivateKey =
  return pepperd.configPepperd.getSectionValue("master", "privateKey").decode().toPrivateKey

proc newPepperd*(): Pepperd = 
  result = Pepperd()
  result.pathPepperd = getAppDir()
  result.createEnvironment()
  result.configPepperd = loadConfig(result.pathConfigPepperd)
  result.httpserver = newAsyncHttpServer()
  result.adminhttpserver = newAsyncHttpServer()
  result.modLoader = newModLoader[MasterModule]()

proc httpCallback(pepperd: Pepperd, request: Request): Future[void] {.async, gcsafe.} =
  # await request.respond(Http400, "http not implemented")
  for module in pepperd.modLoader.modules.values:
    if module.httpCallback.isNil: continue
    if await module.httpCallback(pepperd, request): break
  request.client.close()

proc adminHttpCallback(pepperd: Pepperd, request: Request): Future[void] {.async, gcsafe.} =
  # await request.respond(Http400, "admin http not implemented")
  for module in pepperd.modLoader.modules.values:
    if module.httpCallback.isNil: continue
    if await module.httpAdminCallback(pepperd, request): break
  request.client.close()

proc authenticate(pepperd: Pepperd, request: Request, ws: AsyncWebSocket): Future[Client] {.async, gcsafe.} =
  ## when the connection authenticated, create a client, add it to the
  ## clients list and returns the client, if not raise exception
  result = Client(
    ws: ws, 
    request: request,
    peerAddr: request.client.getPeerAddr
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

    ##Call the module handlers
    for module in pepperd.modLoader.modules.values:
      if module.slaveConnects.isNil: continue
      await module.slaveConnects(pepperd, result)

    return result
  else:
    echo "client is unknown yet, create an unnacepted file."
    pepperd.createUnaccepted(req.senderName, req.senderPublicKey.toString)
    await result.ws.close()
    raise
  echo "[BUG] reached the end... (not possible....)"

proc handleWsMessage(pepperd: Pepperd, oclient: Client): Future[void] {.async.} =
  debug("[pepperd] in handle ws client")

proc wsCallback(pepperd: Pepperd, request: Request, ws: AsyncWebSocket): Future[void] {.async.} =
  var client: Client
  try:  
    client = await pepperd.authenticate(request, ws)
  except:
    echo "authenticate failed somehow"
    echo getCurrentExceptionMsg()
    return
  asyncCheck pepperd.handleWsMessage(client)

iterator targets(pepperd: Pepperd, targets: string): Client =
  var pattern = targets.glob()
  for client in pepperd.clients.values:
    if client.name.matches(pattern):
      yield client

proc findClientByPubKey(pepperd: Pepperd, publicKey: PublicKey): Option[Client] =
  for client in pepperd.clients.values:
    if client.publicKey == publicKey:
      return some(client)
  return

proc slaveinfo(pepperd: Pepperd, adminClient: Client, adminReq: MsgAdminReq): Future[void] {.async.} = 
  discard
  var clientInfos: seq[ClientInfo] = @[]
  for slaveForOutput in pepperd.getAccepted():
    var clientInfo = ClientInfo()
    clientInfo.name = slaveForOutput.slaveName
    clientInfo.publicKey = slaveForOutput.publicKey.encode()
    var clientOpt = pepperd.findClientByPubKey(slaveForOutput.publicKey.toPublicKey)
    if clientOpt.isSome:
      clientInfo.online = true
      clientInfo.ip = clientOpt.get().peerAddr[0]
    else:
      clientInfo.online = false
    clientInfos.add clientInfo

    # Sending the clientInfo
    var adminRes = MsgAdminRes()
    adminRes.target = clientInfo.name #$target.name
    adminRes.output = pack(clientInfo)
    let adminResStr = pack(adminRes)

    try:
      await adminClient.ws.sendBinary(adminResStr)
    except:
      echo getCurrentExceptionMsg()
      continue
  await adminClient.ws.close()

proc trapinfo(pepperd: Pepperd, adminClient: Client, adminReq: MsgAdminReq): Future[void] {.async, gcsafe.} = 
  var adminRes = MsgAdminRes()
  adminRes.target = "none" #$target.name
  adminRes.output = $ await pepperd.modLoader.call(pepperd, "traps.trapinfo", "") #pack(clientInfo)
  let adminResStr = pack(adminRes)

  try:
    await adminClient.ws.sendBinary(adminResStr)
  except:
    echo getCurrentExceptionMsg()
    # continue
  await adminClient.ws.close()  

proc callOnSlaves(pepperd: Pepperd, adminClient: Client, adminReq: MsgAdminReq): Future[void] {.async.} =
  for target in pepperd.targets(adminReq.targets):
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
    # adminRes.json = res.output.json
    let adminResStr = pack(adminRes)

    try:
      await adminClient.ws.sendBinary(adminResStr)
    except:
      echo getCurrentExceptionMsg()
      continue
    echo "sending done..."
  echo "closing"
  await adminClient.ws.close()

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
  
  var adminReq = MsgAdminReq()
  unpack(data, adminReq)

  # TODO these commands should all be modules
  case adminReq.commands
  of "master.slaveinfo":
    echo "GOT master.slaveinfo"
    await pepperd.slaveinfo(adminClient, adminReq)
  of "master.trapinfo":
    echo "GOT master.trapinfo"
    await pepperd.trapinfo(adminClient, adminReq)
  else:
    await pepperd.callOnSlaves(adminClient, adminReq)

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
  for module in pepperd.modLoader.modules.values:
    await callInit(module, pepperd, "")
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

when isMainModule:
  randomize()
  var pepperd = newPepperd()
  pepperd.modLoader.register()
  waitFor pepperd.run()