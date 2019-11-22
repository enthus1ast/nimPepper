# Package

version       = "0.1.5"
author        = "David Krause"
description   = "bulk code execution system / monitoring / traps"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
#bin           = @["nimPepper"]



# Dependencies

requires "nim >= 1.0.9"
requires "miniz"
requires "ed25519"
requires "websocket"
requires "msgpack4nim"
requires "xxtea"
requires "glob"
requires "winim"
requires "winregistry"
requires "cligen"
requires "https://github.com/enthus1ast/illwill.git"
requires "https://github.com/enthus1ast/nimPinger.git"
requires "https://github.com/enthus1ast/nimAsyncUdp.git"
requires "multicast"
requires "flatdb"


const 
  swin = "nim c -d:release --os:windows --opt:speed ./src/nimPepper/pepperslave"
  #slin = "nim c -d:release --os:linux --opt:speed ./src/nimPepper/pepperslave"
  slin = "nim --gcc.exe:musl-gcc --gcc.linkerexe:musl-gcc --passL:-static --passL:-s c -d:release --os:linux --opt:speed ./src/nimPepper/pepperslave"
  pepperd = "nim c -d:release --passL:-s --opt:speed ./src/nimPepper/pepperd"
  pepper = "nim c -d:release --passL:-s --opt:speed ./src/nimPepper/pepper"


task slavewin, "builds slave for windows":
  exec swin
task slavelin, "builds slave for linux":
  exec slin
task slave, "builds slave for windows and linux":
  exec swin
  exec slin
task all, "build pepperslave for all targets (of course no macos because macos is fucked), pepperd for current target, and pepper for current target":
  exec swin
  exec slin
  exec pepperd
  exec pepper  