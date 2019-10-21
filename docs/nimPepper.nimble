# Package

version       = "0.1.0"
author        = "David Krause"
description   = "a remote code execution system"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["nimPepper"]



# Dependencies

requires "nim >= 1.0.9"
requires "msgpack4nim"
requires "xxtea"
requires "glob"
requires "miniz"
requires "websocket"
requires "ed25519"
requires "illwill" # for "slaves online" command
