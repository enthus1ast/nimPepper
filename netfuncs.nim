import pepperdImports
import messages
import logger

proc extractFirstLevel*(data: string, firstLevel: var FirstLevel): bool =
  ## extracts the first level from data soup, 
  ## returns true if sucessfull
  ## false otherwise
  var jsonMsg: JsonNode
  try:
    jsonMsg = parseJson(data)
  except:
    error("could not parse json")
    debug(data)
    return false

  if jsonMsg.contains("senderPublicKey"):
    firstLevel.senderPublicKey = jsonMsg["senderPublicKey"].getStr()
  else:
    error("no senderPublicKey")
    return false

  if jsonMsg.contains("raw"):
    firstLevel.raw = jsonMsg["raw"].getStr()
  else:
    error("no raw")
    return false  

  if jsonMsg.contains("signature"):
    firstLevel.signature = jsonMsg["signature"].getStr()
  else:
    error("no signature")
    return false      
  
  return true