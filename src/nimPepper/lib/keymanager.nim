import typesPepperd
import pepperdImports
import ospaths
import strutils

type
  SlaveForOutput* = object
    slaveName*: string
    publicKey*: string

proc cleanStr(strTainted: TaintedString): string =
  echo "cleanStr not implemented yet"
  result = strTainted.multiReplace(
    ("/", ""), 
    ("..", ""), 
    ("\\", ""), 
    ("#", ""), 
    ("%", ""),
    ("&", ""),
    (" ", "_"),
    ("?", ""),
  ).quoteShell()

proc isUnaccepted*(pepperd: Pepperd, slaveNameTainted: TaintedString, publicKeyStr: string): bool = 
  ## checks if given slave is in unaccepted keys
  let slaveName = slaveNameTainted.cleanStr()
  let path = pepperd.pathUnacceptedKeys / slaveName & ".pubkey"
  if existsFile(path) and ($readFile(path) == publicKeyStr):
    return true
  return false

proc isAccepted*(pepperd: Pepperd, slaveNameTainted: TaintedString, publicKeyStr: string): bool =
  ## checks if given slave is in slaves/ and if public key matches
  let slaveName = slaveNameTainted.cleanStr()
  if not existsDir(pepperd.pathSlaves / slaveName):
    return false
  let path = pepperd.pathSlaves / slaveName / slaveName & ".pubkey"
  if not existsFile(path):
    return false
  if not ($readFile(path) == publicKeyStr):
    return false
  return true

proc getUnaccepted*(pepperd: Pepperd): seq[SlaveForOutput] = 
  var globstr = pepperd.pathUnacceptedKeys / "*.pubkey"
  # echo globstr
  for path in walkFiles(globstr):
    result.add(SlaveForOutput(
      slaveName: path.splitFile.name,
      publicKey: $readFile(path)
    ))

proc getAccepted*(pepperd: Pepperd): seq[SlaveForOutput] =
  var globstr = pepperd.pathSlaves / "*" / "*.pubkey"
  # echo globstr
  for path in walkFiles(globstr):
    result.add(SlaveForOutput(
      slaveName: path.splitFile.name,
      publicKey: $readFile(path)
    ))

proc clearUnaccepted*(pepperd: Pepperd) =
  var globstr = pepperd.pathUnacceptedKeys / "*.pubkey"
  for path in walkFiles(globstr):
    removeFile(path)

proc accept*(pepperd: Pepperd, slaveNameTainted: TaintedString) = 
  ## creates a slave/%slavename% folder and moves over the pubkey
  let slaveName = slaveNameTainted.cleanStr()
  var source = pepperd.pathUnacceptedKeys / slaveName & ".pubkey"
  var targetDir = pepperd.pathSlaves / slaveName
  var target = targetDir / slaveName & ".pubkey"
  createDir(targetDir)
  moveFile(source, target)

# proc delete*(pepperd: Pepperd, slaveName: string) = 
#   ## deletes a given slave's public key


proc unacept*(pepperd: Pepperd, slaveNameTainted: TaintedString) =
  ## removes a client public key from the accepted,
  ## leaves config untouched
  let slaveName = slaveNameTainted.cleanStr()
  var sourceDir = pepperd.pathSlaves / slaveName
  var source = sourceDir / slaveName & ".pubkey"
  var target = pepperd.pathUnacceptedKeys / slaveName & ".pubkey"
  moveFile(source, target)

proc createUnaccepted*(pepperd: Pepperd, slaveNameTainted: TaintedString, publicKeyStr: string) =
  ## creates 
  var slaveName = slaveNameTainted.cleanStr()
  var path = pepperd.pathUnacceptedKeys / slaveName & ".pubkey"
  writeFile(path, publicKeyStr)

when isMainModule:
  import ../pepperd
  var pepd = newPepperd()
  pepd.accept("faa")
  echo pepd.getUnaccepted()
  echo pepd.getAccepted()
