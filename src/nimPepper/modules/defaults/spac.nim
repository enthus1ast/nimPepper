## pac == "platform agnostic commands"
import ../../lib/typesPepperSlave
import ../../lib/moduleLoader
import strutils, os, sequtils, nimPing

var modspac* {.exportc.} = newSlaveModule("pac")

modspac.boundCommands["ls"] = proc(obj: PepperSlave, params: string): Future[JsonNode] {.async, closure.} =
  var outp = ""
  try:
    outp = toSeq(walkPattern(params)).join("\n")
  except:
    outp = getCurrentExceptionMsg()
  return %* {
    "outp": outp,
  }

modspac.boundCommands["cat"] = proc(obj: PepperSlave, params: string): Future[JsonNode] {.async, closure.} =
  var outp = ""
  try:
    outp = readFile(params)
  except:
    outp = getCurrentExceptionMsg()
  return %* {"outp": outp,}

modspac.boundCommands["ping"] = proc(obj: PepperSlave, params: string): Future[JsonNode] {.async, closure.} =
  var outp = ""
  try:
    outp = params & " " & $ping(params)
  except:
    outp = getCurrentExceptionMsg()
  return %* {
    "outp": outp,
  }
