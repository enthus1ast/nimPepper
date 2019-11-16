import cligen, nimPing, strutils

proc cli(url: string): int =
  var res: bool
  try:
    res = ping(url)
  except:
    echo getCurrentExceptionMsg()
    return 2
  if res: return 0
  else: return 2

dispatch cli