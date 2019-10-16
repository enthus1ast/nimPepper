import pepperdImports
type
  MessageConcept* = concept c
    c.messageType is MessageType
  MessageType* {.pure.} = enum
    MsgReq, MsgRes, MsgUntrusted
  MessageEnvelope* = object
    nonce*: string
    messageType*: MessageType
    msg*: string
  # MsgBase* = object of RootObj
  #   version*: byte
  #   messageType*: MessageType
  #   messageId*: string
  #   timestamp*: string
  #   senderName*: string
  #   senderPublicKey*: string    
  # MsgLog* = object of MsgBase
  #   # slave -> master
  #   eventName*: string
  #   eventMsg*: string #|Json
  # MsgLogResp* = object of MsgBase
  # MsgPing* = object of MsgBase
  # MsgPong* = object of MsgBase
  # MsgUntrusted* = object of MsgBase
  # MsgControlReq* = object of MsgBase
  #   # master -> slave
  #   command*: string
  #   param*: string #|Json
  # MsgControlRes* = object of MsgBase
  #   # slave -> master
  #   command*: string
  #   output*: string    
  FirstLevel* = object 
    senderPublicKey*: PublicKey
    raw*: string
    signature*: Signature
  MsgReq* = object
    version*: byte
    messageType*: MessageType
    messageId*: string
    timestamp*: string
    senderName*: string
    senderPublicKey*: string   
    command*: string
    params*: string 
  MsgRes* = object
    version*: byte
    messageType*: MessageType
    messageId*: string
    responseToId*: string
    timestamp*: string
    senderName*: string
    senderPublicKey*: string  
    output*: string