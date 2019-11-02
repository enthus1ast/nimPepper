import pepperdImports
import net
type
  Addr* = (string, Port)
  Client* = object 
    ws*: AsyncWebSocket
    request*: Request
    name*: string
    publicKey*: PublicKey
    peerAddr*: Addr
  Clients* = Table[AsyncWebSocket, Client]
  Pepperd* = ref object
    pathPepperd*: string
    pathSlaves*: string
    pathUnacceptedKeys*: string
    pathConfigDir*: string # dir of config
    pathConfigPepperd*: string # the pepperd config
    configPepperd*: Config
    httpserver*: Asynchttpserver
    adminhttpserver*: Asynchttpserver
    clients*: Clients
    commanders*: Clients
    modLoader*: ModLoader[MasterModule]
  ####### Types for master modules
  MasterModuleInitProc* = proc(obj: Pepperd, params: string): Future[JsonNode]
  MasterModuleUnInitProc* = proc(obj: Pepperd, params: string): Future[JsonNode]
  MasterModuleBoundCommandProc* = proc(obj: Pepperd, params: string): Future[JsonNode]
  MasterModuleBoundCommands* = Table[string, MasterModuleBoundCommandProc]
  MasterModule* = object
    name*: string
    initProc*: MasterModuleInitProc
    boundCommands*: MasterModuleBoundCommands
    unInitProc*: MasterModuleUnInitProc

proc newMasterModule*(name: string): MasterModule =
  result = MasterModule(name: name)
  result.boundCommands = initTable[string, MasterModuleBoundCommandProc]()
