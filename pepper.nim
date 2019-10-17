import parseopt, os, strscans, strutils, base64, terminal
import pepperdImports, typesPepperd, pepperd, keymanager
# var opts = initOptParser()

var pepd = newPepperd()

proc getParamSeq(): seq[string] =
  # echo paramString
  for idx in 1..paramCount():
    result.add paramStr(idx)

proc getParamStr(): string =
  return getParamSeq().join(" ")

proc `$`(slaves: seq[SlaveForOutput]): string = 
  for slave in slaves:
    result.add "\t\"" & slave.slaveName & "\"\t" & slave.publicKey.encode() & "\n"

# echo getParamSeq()
# echo getParamStr()
let params = getParamStr()

const HELP = """
SOME HELP
"""
var regs: seq[(string, string)] = @[]

proc help() = 
  echo HELP
  echo "Valid Commands:"
  echo "###############"
  for reg in regs:
    echo reg[0], "\t#", reg[1]
  # echo regs.join("\n")

var
  ## vars that are set by the command line.
  slaveName: string

# echo scanf("keys accept foo", "keys accept $w", key)
# echo key

template chk(params, pattern: string, doc: string = "", results: untyped = void ): bool = 
  regs.add( (pattern, doc) ) 
  scanf(params, pattern, results)

if chk(params, "keys list$.", "list all keys"):
  echo "show keys"
  setForegroundColor(fgGreen)
  echo "accepted:"
  echo $pepd.getAccepted()
  setForegroundColor(fgRed)
  echo "unaccepted:"
  echo $pepd.getUnaccepted()  
  setForegroundColor(fgDefault)

elif chk(params, "keys list accepted$.", "list accepted keys"):
  setForegroundColor(fgGreen)
  echo "accepted"
  echo $pepd.getAccepted()
  setForegroundColor(fgDefault)

elif chk(params, "keys list unaccepted$.", "lists all unaccepted keys"):
  setForegroundColor(fgRed)
  echo "unaccepted"
  echo $pepd.getUnaccepted()
  setForegroundColor(fgDefault)

elif chk(params, "keys accept $w", "accept the key by its name", slaveName):
  setForegroundColor(fgGreen)  
  echo "ACCEPT: ", slaveName
  pepd.accept(slaveName)
  setForegroundColor(fgDefault)


elif chk(params, "keys unaccept $w", "unaccept the key by its name, leaves slave configuration untouched", slaveName):
  setForegroundColor(fgRed)    
  echo "UNACCEPT: ", slaveName
  pepd.unacept(slaveName)
  setForegroundColor(fgDefault)


elif chk(params, "help", "print this help"):
  help()
else:
  echo "Unknown command given!"
  help()
# discard chk("keys list", "keys list$.")
# discard chk("keys list accepted", "keys list accepted$.")
# discard chk("keys list unaccepted", "keys list unaccepted$.")