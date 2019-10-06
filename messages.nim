type
  MsgLog* = object
    # slave -> master
    messageId*: string
    senderName*: string
    senderPublicKey*: string
    eventName*: string
    eventMsg*: string #|Json    
  MsgControlReq* = object
    # master -> slave
    messageId*: string
    senderName*: string
    senderPublicKey*: string
    command*: string
    param*: string #|Json
  MsgControlRes* = object
    # slave -> master
    messageId*: string
    resToId*: string
    senderName*: string
    senderPublicKey*: string
    command*: string
    output*: string    