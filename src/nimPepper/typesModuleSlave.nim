# # import pepperslaveImports
# import json, asyncdispatch
# export json, asyncdispatch
# import typesPepperSlave
# import tables
# type
#   SlaveModuleInitProc* = proc(obj: PepperSlave, params: string): Future[JsonNode]
#   SlaveModuleUnInitProc* = proc(obj: PepperSlave, params: string): Future[JsonNode]
#   SlaveModuleBoundCommandProc* = proc(obj: PepperSlave, params: string): Future[JsonNode]
#   SlaveModuleBoundCommands* = Table[string, SlaveModuleBoundCommandProc]
#   SlaveModule* = object
#     name*: string
#     initProc*: SlaveModuleInitProc
#     boundCommands*: SlaveModuleBoundCommands
#     unInitProc*: SlaveModuleUnInitProc

# proc newSlaveModule*(name: string): SlaveModule =
#   result = SlaveModule(name: name)
#   result.boundCommands = initTable[string, SlaveModuleBoundCommandProc]()
