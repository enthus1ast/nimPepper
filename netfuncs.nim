import pepperdImports
import messages
import logger

proc genTo[T](str: string): T =
  if str.len != T.len:
      raise newException(ValueError, "string is not " & $T)
  for idx, ch in str:
    result[idx] = ch.byte

proc toPublicKey(str: string): PublicKey = 
  return genTo[PublicKey](str)
  
proc toPrivateKey*(str: string): PrivateKey = 
  return genTo[PrivateKey](str)

proc toSignature(str: string): Signature = 
  return genTo[Signature](str)

proc genToString[T](tt: T): string = 
  result = ""
  for idx in 0..tt.len-1:
    result.add tt[idx].char

proc toString(tt: SharedSecret): string =
  return genToString[SharedSecret](tt)

proc extractFirstLevel*(data: string, firstLevel: var FirstLevel): bool =
  ## extracts the first level from data soup, 
  ## returns true if sucessfull
  ## false otherwise
  var jsonMsg: JsonNode
  try:
    jsonMsg = parseJson(data)
  except:
    echo("could not parse json")
    debug(data)
    return false

  if jsonMsg.contains("senderPublicKey"):
    try:
      firstLevel.senderPublicKey = jsonMsg["senderPublicKey"].getStr().toPublicKey
    except:
      return false
  else:
    echo("no senderPublicKey")
    return false

  if jsonMsg.contains("raw"):
    firstLevel.raw = jsonMsg["raw"].getStr()
  else:
    error("no raw")
    return false  

  if jsonMsg.contains("signature"):
    try:
      firstLevel.signature = jsonMsg["signature"].getStr().toSignature()
    except:
      return false
  else:
    error("no signature")
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
  let uncryptedRaw = decrypt(raw, encryptionKey)
  if uncryptedRaw == "": return false
  else: return true

proc unzipData*(uncryptedRaw: string, unzippedRaw: var string): bool = 
  ## unzips data
  ## returns true on success
  ## false otherwise
  try:
    unzippedRaw = uncompress(uncryptedRaw)
  except:
    return false
  return true