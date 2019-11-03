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
    senderPublicKey*: PublicKey   
    command*: string
    params*: string 
  MsgRes* = object
    version*: byte
    messageType*: MessageType
    messageId*: string
    responseToId*: string
    timestamp*: string
    senderName*: string
    senderPublicKey*: PublicKey  
    output*: string
  MsgAdminReq* = object
    targets*: string
    commands*: string
    commandParams*: string
  MsgAdminRes* = object
    target*: string
    output*: string
    json*: string

  ## Used to inform pepper of online clients
  ClientInfo* = object
    name*: string
    ip*: string
    online*: bool
    publicKey*: string