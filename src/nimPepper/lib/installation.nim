when defined(linux):
  from installationlinux import install
elif defined(windows):
  from installationwindows import install
elif defined(macos):
  from installationmacos import install

proc osinstall*(master: string, port: uint16, publicKey: string, autostart = false): bool =
  install(master, port, publicKey, autostart)

when isMainModule:
  echo osinstall("127.0.0.1", 8989, "pub", true)