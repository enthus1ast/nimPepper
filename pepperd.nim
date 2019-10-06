import messages
import pepperdImports
import typesPepperd
import logging

proc genKeys(pepperd: Pepperd) = 
  let seed = seed()
  var keypair = createKeypair(seed)
  pepperd.configPepperd.setSectionKey(
    "master", 
    "publicKey", 
    encode(keypair.publicKey)
  )
  pepperd.configPepperd.setSectionKey(
    "master", 
    "privateKey", 
    encode(keypair.privateKey)
  )

proc createEnvironment(pepperd: Pepperd) = 
  let slaves = pepperd.pathPepperd / "slaves"
  let unacceptedKeys = pepperd.pathPepperd / "unacceptedKeys"
  let configDirPath = pepperd.pathPepperd / "config"
  if not existsDir(slaves):
    createDir(slaves)
  pepperd.pathSlaves = slaves
  if not existsDir(unacceptedKeys):
    createDir(unacceptedKeys)
  pepperd.pathUnacceptedKeys = unacceptedKeys
  if not existsDir(configDirPath):
    createDir(configDirPath)
  pepperd.pathConfigDir = configDirPath
  pepperd.pathConfigPepperd = pepperd.pathConfigDir / "masterconfig.ini"
  if not existsFile(pepperd.pathConfigPepperd):
    pepperd.configPepperd = newConfig()
    pepperd.genKeys()
    pepperd.configPepperd.setSectionKey("master", "httpport", "8989")
    writeConfig(
      pepperd.configPepperd,
      pepperd.pathConfigPepperd
    )
  else:
    pepperd.configPepperd = loadConfig(pepperd.pathConfigPepperd)

proc newPepperd(): Pepperd = 
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
  if not request.client.isClosed():
    request.client.close()

proc wsCallback(pepperd: Pepperd, request: Request, ws: AsyncWebSocket): Future[void] {.async.} =
  discard
  while true:
    var 
      opcode: Opcode
      data: string
    try:
      (opcode, data) = await ws.readData()
    except:
      debug("[pepperd] ws connection interrupted: ", request.client.getPeerAddr)
      await pepperd.handleLostClient(request, ws)
      break
    debug("[pepperd] got ws frame from: $# opcode: $# \nframe:\n$#" % [
        $request.client.getPeerAddr,
        $opcode,
        data
    ])
    case opcode
    of Close:
      debug("[pepperd] ws connection closed: ", request.client.getPeerAddr)
      await pepperd.handleLostClient(request, ws)
      break
    of Text:
      discard
    of Binary:
      debug("[pepperd] 'binary' ws not implemented: ", request.client.getPeerAddr)
    of Ping:
      debug("[pepperd] 'ping' ws not implemented: ", request.client.getPeerAddr)
    of Pong:
      debug("[pepperd] 'pong' ws not implemented: ", request.client.getPeerAddr)
    of Cont:
      debug("[pepperd] 'cont' ws not implemented: ", request.client.getPeerAddr)

proc httpBaseCallback(pepperd: Pepperd, request: Request): Future[void] {.async.} =
  # echo request
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

when isMainModule:
  var consoleLog = newConsoleLogger()
  addHandler(consoleLog)
  var pepperd = newPepperd()
  waitFor pepperd.run()