import pepperdImports
type
  MessageConcept* = concept c
    c.messageType is MessageType
  MessageType* {.pure.} = enum
    MsgLog, MsgControlReq, MsgControlRes  
  MessageEnvelope* = object
    messageType*: MessageType
    msg*: string
  MsgBase* = ref object of RootObj
    version*: byte
    messageType*: MessageType
    messageId*: string
    timestamp*: string
    senderName*: string
    senderPublicKey*: string    
  MsgLog* = object of MsgBase
    # slave -> master
    eventName*: string
    eventMsg*: string #|Json    
  MsgControlReq* = object of MsgBase
    # master -> slave
    command*: string
    param*: string #|Json
  MsgControlRes* = object of MsgBase
    # slave -> master
    command*: string
    output*: string    
  FirstLevel* = object 
    senderPublicKey*: PublicKey
    raw*: string
    signature*: Signature