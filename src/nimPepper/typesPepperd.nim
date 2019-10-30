import pepperdImports
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