import typesPepperd
import pepperdImports
import ospaths

type
  SlaveForOutput* = object
    slaveName*: string
    publicKey*: string

proc isUnaccepted*(pepperd: Pepperd, slaveName, publicKeyStr: string): bool = 
  ## checks if given slave is in unaccepted keys
  let path = pepperd.pathUnacceptedKeys / slaveName & ".pubkey"
  if existsFile(path) and ($readFile(path) == publicKeyStr):
    return true
  return false

proc isAccepted*(pepperd: Pepperd, slaveName, publicKeyStr: string): bool =
  ## checks if given slave is in slaves/ and if public key matches
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

proc accept*(pepperd: Pepperd, slaveName: string) = 
  ## creates a slave/%slavename% folder and moves over the pubkey
  var source = pepperd.pathUnacceptedKeys / slaveName & ".pubkey"
  var targetDir = pepperd.pathSlaves / slaveName
  var target = targetDir / slaveName & ".pubkey"
  createDir(targetDir)
  moveFile(source, target)

# proc delete*(pepperd: Pepperd, slaveName: string) = 
#   ## deletes a given slave's public key


proc unacept*(pepperd: Pepperd, slaveName: string) =
  ## removes a client public key from the accepted,
  ## leaves config untouched
  var sourceDir = pepperd.pathSlaves / slaveName
  var source = sourceDir / slaveName & ".pubkey"
  var target = pepperd.pathUnacceptedKeys / slaveName & ".pubkey"
  moveFile(source, target)

proc cleanStr(str: string): string =
  echo "cleanStr not implemented yet"
  return str

proc createUnaccepted*(pepperd: Pepperd, slaveNameTainted, publicKeyStr: string) =
  ## creates 
  var slaveName = slaveNameTainted.cleanStr()
  var path = pepperd.pathUnacceptedKeys / slaveName & ".pubkey"
  writeFile(path, publicKeyStr)

when isMainModule:
  import pepperd
  var pepd = newPepperd()
  pepd.accept("faa")
  echo pepd.getUnaccepted()
  echo pepd.getAccepted()



# import typesPepperd
# import pepperdImports
# import ospaths

# type
#   SlaveForOutput = object
#     slaveName: string
#     publicKey: string

# proc isUnaccepted*(pathUnacceptedKeys: string, slaveName, publicKeyStr: string): bool = 
#   ## checks if given slave is in unaccepted keys
#   let path = pathUnacceptedKeys / slaveName & ".pubkey"
#   if existsFile(path) and ($readFile(path) == publicKeyStr):
#     return true
#   return false

# proc isAccepted*(pathSlaves: string, slaveName, publicKeyStr: string): bool =
#   ## checks if given slave is in slaves/ and if public key matches
#   if not existsDir(pathSlaves / slaveName):
#     return false
#   let path = pathSlaves / slaveName / slaveName & ".pubkey"
#   if not existsFile(path):
#     return false
#   if not ($readFile(path) == publicKeyStr):
#     return false
#   return true

# proc getUnaccepted*(pathUnacceptedKeys: string): seq[SlaveForOutput] = 
#   var globstr = pathUnacceptedKeys / "*.pubkey"
#   # echo globstr
#   for path in walkFiles(globstr):
#     result.add(SlaveForOutput(
#       slaveName: path.splitFile.name,
#       publicKey: $readFile(path)
#     ))

# proc getAccepted*(pathSlaves: string): seq[SlaveForOutput] =
#   var globstr = pathSlaves / "*" / "*.pubkey"
#   # echo globstr
#   for path in walkFiles(globstr):
#     result.add(SlaveForOutput(
#       slaveName: path.splitFile.name,
#       publicKey: $readFile(path)
#     ))

# proc accept*(pathUnacceptedKeys, pathSlaves: string, slaveName: string) = 
#   ## creates a slave/%slavename% folder and moves over the pubkey
#   var source = pathUnacceptedKeys / slaveName & ".pubkey"
#   var targetDir = pathSlaves / slaveName
#   var target = targetDir / slaveName & ".pubkey"
#   createDir(targetDir)
#   moveFile(source, target)

# proc cleanStr(str: string): string =
#   echo "cleanStr not implemented yet"
#   return str

# proc createUnaccepted*(pathUnacceptedKeys: string, slaveNameTainted, publicKeyStr: string) =
#   ## creates 
#   var slaveName = slaveNameTainted.cleanStr()
#   var path = pathUnacceptedKeys / slaveName & ".pubkey"
#   writeFile(path, publicKeyStr)

# when isMainModule:
#   import pepperd
#   var pepd = newPepperd()
#   pepd.accept("faa")
#   echo pepd.getUnaccepted()
#   echo pepd.getAccepted()    