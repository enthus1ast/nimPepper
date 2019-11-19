import pepperdImports
type
  MessageConcept* = concept c
    # c.messageType is MessageType
    c.messageId = string
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
    messageId*: string
    timestamp*: string
    senderName*: string # TODO move to message envelope? for failing faster on receive
    command*: string
    params*: string 
  MsgRes* = object
    version*: byte
    messageId*: string
    responseToId*: string
    timestamp*: string
    senderName*: string
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