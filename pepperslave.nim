import pepperdImports
import typesPepperSlave
import logger

proc genKeys(slave: PepperSlave) = 
  let seed = seed()
  var keypair = createKeypair(seed)
  slave.configPepperSlave.setSectionKey(
    "slave", 
    "publicKey", 
    encode(keypair.publicKey)
  )
  slave.configPepperSlave.setSectionKey(
    "slave", 
    "privateKey", 
    encode(keypair.privateKey)
  )

proc createEnvironment(slave: PepperSlave) = 
  let configDirPath = slave.pathPepperSlave / "config"
  if not existsFile(slave.pathConfigPepperSlave):
    slave.configPepperSlave = newConfig()
    slave.genKeys()
  if not existsFile(slave.pathConfigPepperSlave):
    slave.configPepperSlave = newConfig()
    slave.genKeys()
    writeConfig(
      slave.configPepperSlave,
      slave.pathConfigPepperSlave
    )
  else:
    slave.configPepperSlave = loadConfig(slave.pathConfigPepperSlave)

proc newPepperSlave(): PepperSlave = 
  result = PepperSlave()
  result.pathPepperSlave = getCurrentDir()
  # result.config 