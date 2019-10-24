import pepperdImports
import moduleLoader
import json, asyncdispatch
export json, asyncdispatch
# import typesPepperSlave
import tables
# import typesModuleSlave
# import pepperslaveImports

type
  PepperSlave* = ref object
    configSlave*: Config
    pathConfigDir*: string # the dir of the config
    pathPepperSlave*: string # the path where the executable is
    pathConfigPepperSlave*: string # the path to the config file
    ws*: AsyncWebSocket
    modLoader*: ModLoader[SlaveModule]

  ######## Types for slave modules
  SlaveModuleInitProc* = proc(obj: PepperSlave, params: string): Future[JsonNode]
  SlaveModuleUnInitProc* = proc(obj: PepperSlave, params: string): Future[JsonNode]
  SlaveModuleBoundCommandProc* = proc(obj: PepperSlave, params: string): Future[JsonNode]
  SlaveModuleBoundCommands* = Table[string, SlaveModuleBoundCommandProc]
  SlaveModule* = object
    name*: string
    initProc*: SlaveModuleInitProc
    boundCommands*: SlaveModuleBoundCommands
    unInitProc*: SlaveModuleUnInitProc

proc newSlaveModule*(name: string): SlaveModule =
  result = SlaveModule(name: name)
  result.boundCommands = initTable[string, SlaveModuleBoundCommandProc]()
