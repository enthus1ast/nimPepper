import pepperdImports
type
  Addr* = (string, Port)
  # ClientInfo* = object
  #   request: Request
  #   ws: AsyncWebSocket
  #   peerAddr: Addr
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
    clients*: Clients