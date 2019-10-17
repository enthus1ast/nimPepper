import typesPepperd
import pepperdImports

proc genKeys*(pepperd: Pepperd) = 
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

proc createEnvironment*(pepperd: Pepperd) = 
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
