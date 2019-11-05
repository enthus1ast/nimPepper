# Package

version       = "0.1.0"
author        = "David Krause"
description   = "bulk code execution system"
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


var swin = "nim c -d:release --os:windows --opt:speed ./src/nimPepper/pepperslave"
var slin = "nim c -d:release --os:linux --opt:speed ./src/nimPepper/pepperslave"

task slavewin, "builds slave for windows":
  exec swin
task slavelin, "builds slave for linux":
  exec slin
task slave, "builds slave for windows and linux":
  exec swin
  exec slin

