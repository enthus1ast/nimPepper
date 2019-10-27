when defined(linux):
  from installationlinux import install
elif defined(windows):
  from installationwindows import install
elif defined(macos):
  from installationmacos import install

proc osinstall*(master: string, port: uint16, publicKey: string, autostart = false): bool =
  install(master, port, publicKey, autostart)
  # when defined(linux):
  #   echo "on linux"
  # elif defined(windows):
  #   echo "on windows"
  # elif defined(macos):
  #   echo "on macos"
  # else:
  #   echo "operating system unsupported."

# proc installLinux(master: string, port: uint16, autostart = false)
  
when isMainModule:
  echo osinstall("127.0.0.1", 8989, true)