import pepperdImports
type
  Client* = object 
    ws*: AsyncWebSocket
    request*: Request
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