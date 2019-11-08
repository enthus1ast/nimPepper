import lib/pepperdImports
import lib/typesPepperSlave
import lib/logger
import lib/netfuncs
import lib/messages
import lib/pepperslaveImports
import lib/installation
import modules.slaveModules
import json

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
    slave.configSlave =  loadConfig(slave.pathConfigPepperSlave)

proc getMasterHost(slave: PepperSlave): string = 
  return "$#:$#" % [
    slave.configSlave.getSectionValue("master", "server"),
    slave.configSlave.getSectionValue("master", "port")
  ]

proc newSubstitutionContext(slave: PepperSlave): StringTableRef = 
  result = newStringTable(modeCaseSensitive)
  result["slavedir"] = getAppDir()
  result["modules"] = getAppDir() / "modules/"
  result["masterhost"] = slave.configSlave.getSectionValue("master", "server") 
  result["masterport"] = slave.configSlave.getSectionValue("master", "port") 
  result["master"] = slave.getMasterHost()

proc newPepperSlave(): PepperSlave = 
  result = PepperSlave()
  result.pathPepperSlave = getAppDir()
  result.createEnvironment()
  result.modLoader = ModLoader[SlaveModule]()
  result.substitutionContext = newSubstitutionContext(result)

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

proc sub(str: string, substitutionContext: StringTableRef): string =
  `%`(str, substitutionContext, {useEnvironment, useKey})

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

    var msgReq = MsgReq()
    unpack(envelope.msg, msgReq)
    let outp = await call[SlaveModule, PepperSlave](
      slave.modLoader, 
      slave, 
      msgReq.command.sub(slave.substitutionContext), 
      msgReq.params.sub(slave.substitutionContext)
    )

    var msgRes = MsgRes()
    msgRes.senderName = hostname()
    msgRes.senderPublicKey = slave.myPublicKey()
    msgRes.output = $ outp
    # echo "Going to send"
    await slave.send(msgRes)

proc connectToMaster(slave: PepperSlave): Future[void] {.async.} = 
  var masterHost = slave.getMasterHost()
  info("[slave] connecting to master: ", masterHost)
  slave.ws = await newAsyncWebsocketClient(
    slave.configSlave.getSectionValue("master", "server"),
    slave.configSlave.getSectionValue("master", "port").parseInt.Port,
    path = "/",
    protocols = @["pepper"]
  )
  await slave.handleConnection()

proc run(slave: PepperSlave): Future[void] {.async.} =
  while true:
    try:
      await slave.connectToMaster()
    except:
      echo getCurrentExceptionMsg()
      echo("[slave] Could not connect to master: ", slave.getMasterHost)
    await sleepAsync(5_000)

import cligen
proc cli(slave: PepperSlave) = 
  proc install(master: string, port: uint16, publicKey: string, autostart = false): int=
    ## Install on a slave node
    if osinstall(master, port, publicKey, autostart):
      echo "[+] installation sucessfull!"
    else:
      echo "[-] installation failure."
    result = 0        # Of course, real code would have real logic here
  
  proc changeMaster(master: string, port: uint16 = 8989, publicKey: string = ""): int =
    slave.configSlave.setSectionKey("master", "server", master)
    slave.configSlave.setSectionKey("master", "port", $port)
    if publicKey != "":
      slave.configSlave.setSectionKey("master", "publicKey", publicKey)
    slave.configSlave.writeConfig(slave.pathConfigPepperSlave)
    result = 0
  
  proc showkey(): int =
    ## Prints the configured public key
    echo "-> PubSlave: ", slave.configSlave.getSectionValue("slave", "publicKey")
    echo "PubMaster: ", slave.configSlave.getSectionValue("master", "publicKey")
    result = 0

  proc triggerTrap(trapName: string) =
    ## triggers a trap on the master by its name `trapName, then exits
    discard

  if paramCount() > 0:
    dispatchMulti([install],  [showkey], [changeMaster], [triggerTrap])


when isMainModule:
  randomize()
  var slave = newPepperSlave()
  slave.cli()
  register(slave.modLoader, slave)
  echo "Available commands:"
  echo slave.modLoader.listCommands().join("\n")
  asyncCheck slave.run()
  runForever()