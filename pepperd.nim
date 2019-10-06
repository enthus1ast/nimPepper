import messages
import miniz
import ed25519
import pepperdImports
import typesPepperd

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
  # pepperd.configPepperd.writeConfig(pepperd.pathConfigPepperd)

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

when isMainModule:
  var pepperd = newPepperd()