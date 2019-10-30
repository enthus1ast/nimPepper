import asynchttpserver, os, strutils, json

var basePath = "slaves/linux/"

proc getLatest(dir: string = "www/slaves/linux/"): string = 
  ## returns the latest version directory
  var latest: int = 0
  var latestFullPath = ""
  for path in walkPattern(dir / "*"):
    var cur: int
    try:
      cur = path.splitPath.tail.parseInt
    except:
      continue
    if cur > latest:
      cur = latest
      latestFullPath = path
  return latestFullPath

proc listing(base, dir: string): JsonNode = 
  result = newJArray()
  for kind, path in walkDir(base / dir, false):
    echo kind, path
    result.add  (%* {"kind": kind, "path": path.relativePath(base)})

# proc httpCallback(pepperd: Pepperd, request: Request): Future[void] {.async.} =
#   await request.respond(Http400, "http not implemented")
#   request.client.close()

when isMainModule:
  echo getLatest(basePath)
  echo listing("www", basePath)