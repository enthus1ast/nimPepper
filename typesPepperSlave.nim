import pepperdImports
type
  PepperSlave* = ref object
    configPepperSlave*: Config
    pathPepperSlave*: string
    pathConfigPepperSlave*: string
