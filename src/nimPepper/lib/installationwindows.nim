## on windows we use nssm for now ( https://nssm.cc/ )
import os, strutils

const SERVICENAME = "pepperslave"
let DEFAULT_PATH = getEnv("programfiles") / "pepperslave"

proc install*(master: string, port: uint16, pubKey: string, autostart = false): bool =
  try:
    var res = 0
    echo "[+] creating dirs"
    createDir(DEFAULT_PATH)
    DEFAULT_PATH.setFilePermissions({fpUserExec, fpUserWrite, fpUserRead})
    let newFile = DEFAULT_PATH / getAppFilename().extractFilename
    
    echo "[+] copy files"
    copyFile(getAppFilename(), newFile )
    newFile.setFilePermissions({fpUserExec, fpUserWrite, fpUserRead})

    let 
      nssmold = getAppDir() / "nssm.exe"
      nssmnew = DEFAULT_PATH / "nssm.exe"
    if not fileExists(nssmold):
      echo "[-] nssm not found at: ", nssmold
      quit()
    copyFile(nssmold, nssmnew)
    nssmnew.setFilePermissions({fpUserExec, fpUserWrite, fpUserRead})  

    echo "[+] change config"
    res = execShellCmd("\"$#\" changeMaster --master:$# --port:$# --publicKey:$#" % 
      [newFile, master, $port, pubKey])
    if res != 0: raise 

    echo "[+] adding autostart (installing nssm)"
    # WINDOWS DRIVES ME CRAZY fix this vvvvv
    var cmd = "\"" & "\"$#\" install $# \"$#\" Start Automatic" % [nssmnew, SERVICENAME, newFile.replace(" ", "\\ ")] & "\""
    echo cmd
    res = execShellCmd( cmd )
    if res != 0: raise 
    return true
  except:
    echo getCurrentExceptionMsg()
    return false  

when isMainModule:
  echo install("MASTERPORT", 1337.uint16, "PUBKEY", autostart = true)