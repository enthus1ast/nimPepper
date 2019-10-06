import pepperdImports
import typesPepperSlave
import logger
import netfuncs
import messages

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

proc getMasterHost(slave: PepperSlave): string = 
  return "$#:$#" % [
    slave.configSlave.getSectionValue("master", "server"),
    slave.configSlave.getSectionValue("master", "port")
  ]



proc handleConnection(slave: PepperSlave): Future[void] {.async.} = 
  while true:
    let raw = "FOOO"
    var zippedRaw: string = ""
    if not zipData(raw, zippedRaw):
      debug("[slave] could not zip data")
      return
    
    let myPrivatKey = slave.configSlave.getSectionValue("slave", "privateKey").decode().toPrivateKey
    let myPublicKey = slave.configSlave.getSectionValue("slave", "publicKey").decode().toPublicKey
    let receiverPublicKey = slave.configSlave.getSectionValue("master", "publicKey").decode().toPublicKey
    var cryptedRaw: string = ""
    if not encryptData(myPrivatKey, receiverPublicKey, zippedRaw, cryptedRaw):
      debug("[slave] could not encrypt data")
      return
    
    echo "cryptedRaw: ",cryptedRaw.len

    var signature: Signature
    if not genSignature(myPrivatKey, myPublicKey, cryptedRaw, signature):
      debug("[slave] could not generate signature")
      return

    # signature[0] = '1'.byte
    # cryptedRaw[0] = '1'.char

    var firstLevel: FirstLevel
    firstLevel.senderPublicKey = myPublicKey
    firstLevel.raw = cryptedRaw
    firstLevel.signature = signature

    var firstLevelMsg = pack(firstLevel)


    # var firstLevelJson = %* {
    #   "senderPublicKey": firstLevel.senderPublicKey.toString,
    #   "raw": firstLevel.raw,
    #   "signature": firstLevel.signature.toString
    # }
    echo $firstLevelMsg

    await sendBinary(slave.ws, firstLevelMsg)
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
    await sleepAsync(1000)

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
  # asyncCheck slave.ping()
  asyncCheck slave.run()
  runForever()