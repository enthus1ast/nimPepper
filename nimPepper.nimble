# Package

version       = "0.1.0"
author        = "David Krause"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["nimPepper"]



# Dependencies

requires "nim >= 1.0.9"
requires "miniz"
requires "ed25519"
requires "https://git.code0.xyz/sn0re/illwill.git"
requires "websocket"
requires "msgpack4nim"


