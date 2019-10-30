import pepperdImports
import messages
import logger
import json

proc genTo[T](str: string): T =
  if str.len != T.len:
      raise newException(ValueError, "string is not " & $T)
  for idx, ch in str:
    result[idx] = ch.byte

proc toPublicKey*(str: string): PublicKey = 
  return genTo[PublicKey](str)
  
proc toPrivateKey*(str: string): PrivateKey = 
  return genTo[PrivateKey](str)

proc toSignature*(str: string): Signature = 
  return genTo[Signature](str)

proc genToString[T](tt: T): string = 
  result = ""
  for idx in 0..tt.len-1:
    result.add tt[idx].char

proc toString*(tt: SharedSecret|PublicKey): string = ## todo not needet??
  return genToString[SharedSecret](tt)

proc toString*(tt: Signature|PrivateKey): string = ## todo not needet??
  return genToString[Signature](tt)

proc extractFirstLevel*(data: string, firstLevel: var FirstLevel): bool =
  ## extracts the first level from data soup, 
  ## returns true if sucessfull
  ## false otherwise
  try:
    unpack(data, firstLevel)
  except:
    echo "could not unpack"
    return false
  return true

proc verifySignature*(firstLevel: FirstLevel): bool = 
  verify(
    firstLevel.raw,
    firstLevel.signature,
    firstLevel.senderPublicKey
  )

proc uncryptData*(myPrivateKey: PrivateKey, senderPublicKey: PublicKey, 
    raw: string, uncryptedRaw: var string): bool =
  ## uncrypts data
  ## returns true on sucess 
  ## false otherwise
  let encryptionKey: string = keyExchange(senderPublicKey, myPrivateKey).toString()
  uncryptedRaw = decrypt(raw, encryptionKey)
  if uncryptedRaw == "": return false
  else: return true

proc unzipData*(uncryptedRaw: string, unzippedRaw: var string): bool = 
  ## unzips data
  ## returns true on success
  ## false otherwise
  try:
    unzippedRaw = uncompress(uncryptedRaw)
    # echo unzippedRaw.len
  except:
    echo getCurrentExceptionMsg()
    return false
  return true

proc zipData*(raw: string, zippedRaw: var string): bool = 
  try:
    zippedRaw = compress(raw)
  except:
    return false
  return true

proc encryptData*(myPrivateKey: PrivateKey, receiverPublicKey: PublicKey,
    raw: string, cryptedRaw: var string): bool =
  try:
    let encryptionKey: string = keyExchange(receiverPublicKey, myPrivateKey).toString()
    cryptedRaw = encrypt(raw, encryptionKey)
  except:
    return false
  return true

proc genSignature*(myPrivateKey: PrivateKey, myPublicKey: PublicKey,
    raw: string, signature: var Signature): bool = 
  var keyPair: KeyPair = (myPublicKey, myPrivateKey)
  try:
    signature = sign(raw, keyPair)
  except:
    return false
  return true
  
proc unpackFromFirstLevel*(myPrivateKey: PrivateKey, firstLevel: FirstLevel, data: var string): bool =
  let senderPublicKey = firstLevel.senderPublicKey
  if not verifySignature(firstLevel):
    info("[pepperd] could not verify signature on data")
    return false

  var uncryptedRaw: string = ""
  let raw = firstLevel.raw
  if not uncryptData(myPrivateKey, senderPublicKey, raw, uncryptedRaw):
    info("[pepperd] could not uncrypt data!")
    return false

  if not unzipData(uncryptedRaw, data):
    info("[pepperd] could not uncompress data!")
    return false
  return true

proc packToFirstLevel*(myPrivatKey: PrivateKey, myPublicKey, receiverPublicKey: PublicKey, 
    data: string, firstLevel: var FirstLevel): bool =
  ## compress, encrypt and signs a message
  var zippedRaw: string = ""
  if not zipData(data, zippedRaw):
    debug("[slave] could not zip data")
    return false
  
  var cryptedRaw: string = ""
  if not encryptData(myPrivatKey, receiverPublicKey, zippedRaw, cryptedRaw):
    debug("[slave] could not encrypt data")
    return false
  
  var signature: Signature
  if not genSignature(myPrivatKey, myPublicKey, cryptedRaw, signature):
    debug("[slave] could not generate signature")
    return false

  firstLevel.senderPublicKey = myPublicKey
  firstLevel.raw = cryptedRaw
  firstLevel.signature = signature
  return true  

proc randomString(len: int = 10): string = 
  result = ""
  for idx in 0..len-1:
    result.add(random(255).char)

proc packEnvelope*(msg: MessageConcept): MessageEnvelope = 
  result = MessageEnvelope()
  result.nonce = randomString(random(10))
  result.messageType = msg.messageType
  result.msg = pack(msg)

proc openEnvelope*(str: string, envelope: var MessageEnvelope): bool = 
  try:
    unpack(str, envelope)
  except:
    return false
  return true

proc unpack*(myPrivateKey: PrivateKey, data: string, firstLevel: var FirstLevel, envelope: var MessageEnvelope): bool = 
  ## unpacks and decrypts everything
  if not extractFirstLevel(data, firstLevel):
    info("[pepperd] could not extract firstLevel: ") #, client.peerAddr)
    return false

  var unzippedRaw: string = ""
  if not unpackFromFirstLevel(myPrivateKey, firstLevel, unzippedRaw):
    info("[pepperd] could not unpackFromFirstLevel") 
    return false

  if not openEnvelope(unzippedRaw, envelope):
    info("[pepperd] could not unpackEnvelope")
    return false
  return true
