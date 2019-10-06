import pepperdImports
type
  PepperSlave* = ref object
    configSlave*: Config
    pathConfigDir*: string # the dir of the config
    pathPepperSlave*: string # the path where the executable is
    pathConfigPepperSlave*: string # the path to the config file
    ws*: AsyncWebSocket
