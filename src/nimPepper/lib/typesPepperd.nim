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
  MasterModuleBoundAdminCommandProc* = proc(obj: Pepperd, params: string): Future[JsonNode]
  MasterModuleBoundAdminCommands* = Table[string, MasterModuleBoundAdminCommandProc]  
  MasterModuleSlaveConnectsProc* = proc(obj: Pepperd, client: Client): Future[void]
  MasterModuleSlaveDisConnectsProc* = proc(obj: Pepperd, client: Client): Future[void]
  MasterModule* = object
    name*: string
    initProc*: MasterModuleInitProc
    boundCommands*: MasterModuleBoundCommands
    boundAdminCommands*: MasterModuleBoundAdminCommands
    unInitProc*: MasterModuleUnInitProc
    slaveConnects*: MasterModuleSlaveConnectsProc
    slaveDisconnects*: MasterModuleSlaveDisConnectsProc

proc newMasterModule*(name: string): MasterModule =
  result = MasterModule(name: name)
  result.boundCommands = initTable[string, MasterModuleBoundCommandProc]()
  result.boundAdminCommands = initTable[string, MasterModuleBoundAdminCommandProc]()
