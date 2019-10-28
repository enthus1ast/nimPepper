import messages
import netfuncs
import json
import base64

proc pack(firstLevel: FirstLevel): string = 
  return $ %* {
    "senderPublicKey": firstLevel.senderPublicKey.toString().encode(),
    "raw": firstLevel.raw,
    "signature": firstLevel.signature.toString().encode()
  }

proc unpackFirstLevel(str: string): FirstLevel =
  let strj = parseJson(str)
  result = FirstLevel(
    senderPublicKey: strj["senderPublicKey"].getStr().decode().toPublicKey(),
    raw: strj["raw"].getStr(),
    signature: strj["signature"].getStr().decode().toSignature()
  )


when isMainModule:
  import unittest
  import base64
  import strutils
  var buf: string
  suite "firstLevel":
    setup:
      let firstLevel = FirstLevel(
        senderPublicKey: "m+5oZuoWmtVVzlsyX4FfBJoI3LC99BzdIARYXJjm9Xs=".decode().toPublicKey,
        raw: "foo",
        signature: "a".repeat(64).toSignature()
      )
    test "pack":
      buf = pack(firstLevel)
    test "unpack":
      var fl = unpackFirstLevel(buf)
      check firstLevel == fl
  suite "mesageEnvelope":
    setup:
      let messageEnvelope = MessageEnvelope(
        nonce: "m+5oZuoWmtVVzlsyX4FfBJoI3LC99BzdIARYXJjm9Xs=".decode(), # for test with binary
        messageType: MessageType.MsgPing,
        msg: "asdf"
      )
    
