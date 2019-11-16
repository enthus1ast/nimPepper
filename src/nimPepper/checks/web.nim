import cligen, httpclient, strutils


proc cli(url: string, contains = "", code = 0): int =
  discard
  var client = newHttpClient()
  var res: Response
  try:
    res = client.get(url)
  except:
    echo getCurrentExceptionMsg()
    return 2
  if contains != "":
    if res.body.contains(contains): result = 0
    else: return 2
  if code != 0:
    if res.code().int == code: result = 0
    else: return 2

dispatch cli