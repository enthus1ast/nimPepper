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
  
proc toSignature(str: string): Signature = 
  return genTo[Signature](str)

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
