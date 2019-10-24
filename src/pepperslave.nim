import pepperdImports
import typesPepperSlave
import logger
import netfuncs
import messages
import json
import pepperslaveImports
import modules.slaveModules

proc genKeys(slave: PepperSlave) = 
  let seed = seed()
  var keypair = createKeypair(seed)
  slave.configSlave.setSectionKey(
    "slave", 
    "publicKey", 
    encode(keypair.publicKey)
  )
  slave.configSlave.setSectionKey(
    "slave", 
    "privateKey", 
    encode(keypair.privateKey)
  )

proc createEnvironment(slave: PepperSlave) = 
  let configDirPath = slave.pathPepperSlave / "configSlave"
  if not existsFile(slave.pathConfigPepperSlave):
    slave.configSlave = newConfig()
    slave.genKeys()
  if not existsDir(configDirPath):
    createDir(configDirPath)
  slave.pathConfigDir = configDirPath
  slave.pathConfigPepperSlave = configDirPath / "slaveconfig.ini"
  if not existsFile(slave.pathConfigPepperSlave):
    slave.configSlave = newConfig()
    slave.genKeys()
    writeConfig(
      slave.configSlave,
      slave.pathConfigPepperSlave
    )
  else:
    slave.configSlave = loadConfig(slave.pathConfigPepperSlave)

proc newPepperSlave(): PepperSlave = 
  result = PepperSlave()
  result.pathPepperSlave = getCurrentDir()
  result.createEnvironment()
  result.modLoader = ModLoader[PepperSlave]()

proc getMasterHost(slave: PepperSlave): string = 
  return "$#:$#" % [
    slave.configSlave.getSectionValue("master", "server"),
    slave.configSlave.getSectionValue("master", "port")
  ]

proc recvData(slave: PepperSlave): Future[(Opcode, string)] {.async.} =
  var 
    opcode: Opcode
    data: string
  try:
    (opcode, data) = await slave.ws.readData()
  except:
    debug("[slave] ws connection interrupted: ") #, client.request.client.getPeerAddr)
    # await pepperd.handleLostClient(client.request, client.ws)
    raise
  case opcode
  of Close:
    debug("[pepperd] ws connection closed: ") #, client.peerAddr)
    # await pepperd.handleLostClient(client.request, client.ws)
    raise 
  of Text:
    debug("[pepperd] 'text' ws not implemented: ") #, client.peerAddr)
  of Binary:
    return (opcode, data)
  of Ping:
    debug("[pepperd] 'ping' ws not implemented: ") #, client.peerAddr)
    raise
  of Pong:
    debug("[pepperd] 'pong' ws not implemented: ") #, client.peerAddr)
    raise
  of Cont:
    debug("[pepperd] 'cont' ws not implemented: ") #, client.peerAddr)  
    raise

proc recv(slave: PepperSlave): Future[tuple[firstLevel: FirstLevel, envelope: MessageEnvelope]] {.async.} =
    var 
      opcode: Opcode
      data: string
    try:
      (opcode, data) = await slave.recvData()
    except: 
      raise
    # echo "RECV:", opcode, "\n", data
  
    let myPrivateKey = slave.configSlave.getSectionValue("slave", "privateKey").decode().toPrivateKey
    if not unpack(myPrivateKey, data, result.firstLevel, result.envelope):
      debug("[slave] could not unpack the whole message")
      raise

proc myPublicKey(slave: PepperSlave): PublicKey =
  return slave.configSlave.getSectionValue("slave", "publicKey").decode().toPublicKey

proc myPrivateKey(slave: PepperSlave): PrivateKey =
  return slave.configSlave.getSectionValue("slave", "privateKey").decode().toPrivateKey

proc masterPublicKey(slave: PepperSlave): PublicKey =
  return slave.configSlave.getSectionValue("master", "publicKey").decode().toPublicKey  

proc send(slave: PepperSlave, msg: MessageConcept): Future[void] {.async.} = 
  let myPrivatKey = slave.myPrivateKey()
  let myPublicKey = slave.myPublicKey()
  let receiverPublicKey = slave.masterPublicKey()
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
  await sendBinary(slave.ws, firstLevelMsg)


proc handleConnection(slave: PepperSlave): Future[void] {.async.} =   
  var helo = MsgReq()
  helo.messageType = MessageType.MsgReq
  helo.command = "helo"
  helo.senderName = hostname()
  helo.senderPublicKey = slave.myPublicKey()
  await slave.send(helo)

  while true:
    var 
      firstLevel: FirstLevel
      envelope: MessageEnvelope 
    try:
      (firstLevel, envelope) = await slave.recv()
    except:
      break
    echo firstLevel
    echo envelope

    var msgReq = MsgReq()
    unpack(envelope.msg, msgReq)

    let outp = await slave.modLoader.call(slave, msgReq.command, msgReq.params)

    var msgRes = MsgRes()
    msgRes.senderName = hostname()
    msgRes.senderPublicKey = slave.myPublicKey()
    msgRes.output = $ outp
    echo "Going to send"
    await slave.send(msgRes)
    # var signature: string = ""
    # if not 
    # if slave.ws.sock.isClosed:
    #   info("[slave] lost connection")
    #   return
    # # echo repr slave.ws
    # echo "SEND"
    # echo slave.ws.sock.isClosed
    # echo repr slave.ws.sock.getFd
    # await sendText(slave.ws, "FOO".repeat(1000))
    # # let (opcode, data) = await slave.ws.readData()
    # await sleepAsync(1000)

proc connectToMaster(slave: PepperSlave): Future[void] {.async.} = 
  var masterHost = slave.getMasterHost()
  info("[slave] connecting to master: ", masterHost)
  slave.ws = await newAsyncWebsocketClient(
    slave.configSlave.getSectionValue("master", "server"),
    slave.configSlave.getSectionValue("master", "port").parseInt.Port,
    path = "/",
    protocols = @["pepper"]
  )
  # slave.ws.sock.getFd.setSockOpt(SO_KEEPALIVE, true)
  await slave.handleConnection()

# proc ping(slave: PepperSlave): Future[void] {.async.} = 
#   while true:
#     await sleepAsync(6000)
#     echo "ping"
#     await slave.ws.sendPing()

proc run(slave: PepperSlave): Future[void] {.async.} =
  while true:
    try:
      await slave.connectToMaster()
    except:
      echo getCurrentExceptionMsg()
      echo("[slave] Could not connect to master: ", slave.getMasterHost)
    await sleepAsync(5_000)

when isMainModule:
  var slave = newPepperSlave()
  register(slave.modLoader, slave)
  echo "Available commands:"
  echo slave.modLoader.listCommands().join("\n")
  # asyncCheck slave.ping()
  asyncCheck slave.run()
  runForever()