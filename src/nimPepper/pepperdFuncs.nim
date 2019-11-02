import pepperdImports
import typesPepperd
import netfuncs
import messages
import hashes

proc hash*(ws: AsyncWebSocket): Hash = 
  var h: Hash = 0
  h = h !& hash(ws.sock.getFd)
  # h = h !& hash
  return h

proc handleLostClient*(pepperd: Pepperd, request: Request, ws: AsyncWebSocket): Future[void] {.async, gcsafe.} =
  info("[pepperd] lost client: ") #,  #request.client.getPeerAddr)
  if pepperd.clients.contains(ws):
    var client = pepperd.clients[ws]
    # # Call the module handlers
    for module in pepperd.modLoader.modules.values:
      if module.slaveDisconnects.isNil: continue
      await module.slaveDisconnects(pepperd, client)  
    debug("[pepperd] remove ws from clients table")
    pepperd.clients.del(ws)
  if not request.client.isClosed():
    request.client.close()


proc send*(pepperd: Pepperd, client: Client, msg: MessageConcept): Future[void] {.async.} =
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

proc recvData*(pepperd: Pepperd, client: Client): Future[(Opcode, string)] {.async.} = 
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

proc recv*(pepperd: Pepperd, client: Client): Future[tuple[firstLevel: FirstLevel, envelope: MessageEnvelope]] {.async.} =
  var 
    opcode: Opcode
    data: string
  try:
    (opcode, data) = await pepperd.recvData(client)
  except: 
    await pepperd.handleLostClient(client.request, client.ws)
    raise
  let myPrivateKey = pepperd.configPepperd.getSectionValue("master", "privateKey").decode().toPrivateKey
  if not unpack(myPrivateKey, data, result.firstLevel, result.envelope):
    debug("[pepperd] could not unpack the whole message")
    raise