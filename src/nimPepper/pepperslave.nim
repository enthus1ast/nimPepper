import lib/pepperdImports
import lib/typesPepperSlave
import lib/logger
import lib/netfuncs
import lib/messages
import lib/pepperslaveImports
import lib/installation
import modules.slaveModules
import json
import strutils
import modules.defaults.sharedmasterfind
import asyncudp, net
import modules.defaults.trapshared


const 
  RECV_TIMEOUT = 60_000 # after this time of no message from the server, we think we're offline

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
    debug("[slave] ws connection interrupted: ") 
    echo getCurrentExceptionMsg()
    #, client.request.client.getPeerAddr)
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
      var recvFut = slave.recvData()
      var intime = await withTimeout(recvFut, RECV_TIMEOUT)
      if intime:
        (opcode, data) = await recvFut
      else:
        echo "[pepperslave] master send us nothing, timeout!"
        raise newException(IOError, "recv timed out!")
    except: 
      echo getCurrentExceptionMsg()
      raise
  
    let myPrivateKey = slave.configSlave.getSectionValue("slave", "privateKey").decode().toPrivateKey
    if not unseal(myPrivateKey, data, result.firstLevel, result.envelope):
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
  if not seal(
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
      if (not slave.ws.isNil) and (not slave.ws.sock.isNil) and (not slave.ws.sock.isClosed): # todo maybe to paranoid?
        slave.ws.sock.close() # close the connection in case of error
    await sleepAsync(5_000)

import cligen
import httpclient

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

  proc triggerTrap(trap: string, good = false, bad = false, data = ""): int =
    ## triggers a trap on the master by its name `trapName, then exits
    const magicTrapBody = "bum"
    if good and bad: 
      echo "either 'good' OR 'bad' not both"
      return 1
    if (not good) and (not bad):
      echo "was it 'good' OR 'bad' ??"
      return 1
    discard
    var trapTrigger = TrapTrigger(
      trap: trap,
      good: good,
      bad: bad,
      data: data,
      dateCreated: $now()
    )
    let js = %* trapTrigger
    ## TODO compress sign and crypt the body!
    

    var client = newHttpclient()
    var res: Response
    # var error: false
    try:
      res = client.post(
        "http://$host/trap/$trap/$slave" % [
          "host", slave.getMasterHost(),
          "trap", trap, # TODO encode html
          "slave", hostname() # TODO encode html
        ], 
        body = $js
      )
    except:
      # error = true
      echo "could not trigger trap ($trap):" % ["trap", trap], getCurrentExceptionMsg()
      quit() ## TODO save the trap trigger somewhere and send later 
    
    if res.status != Http200:
      echo "could reach server but not Http200"
      quit()
    if res.body != magicTrapBody:
      echo "no magic trap body"
      quit()
    # echo repr res


  proc masterfind() = 
    ## tries to find a pepperd master on the network, 
    ## useing udp multicast, tries to find as many masters as possible, 
    ## must be canceled with crtl+c
    var socket = newAsyncSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
    waitFor socket.sendTo(multicastGroup, multicastPort.Port, magicReq)
    while true:
      var res = waitFor socket.recvFrom(1024)
      if res.data.startsWith(magicRes):
        let parts = res.data.split()
        if parts.len >= 3:
          try:
            let port = parseInt(parts[1]).Port
            let pubkey = parts[2]
            echo "found master:\n$#:$# $#" % [res.address, $port, pubkey]
          except:
            discard


  if paramCount() > 0:
    dispatchMulti([install],  [showkey], [changeMaster], [triggerTrap], [masterfind])



when isMainModule:
  randomize()
  var slave = newPepperSlave()
  slave.cli()
  register(slave.modLoader, slave)
  echo "Available commands:"
  echo slave.modLoader.listCommands().join("\n")
  asyncCheck slave.run()
  runForever()