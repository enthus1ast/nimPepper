import times, strutils, sequtils


proc parseDuration*(str: string): Duration = 
  ## parses a string like: "1 days 12 hours" into a `Duration`
  result = initDuration()
  var parts = str.split()
  if parts.len == 0:
    raise newException(ValueError, "empty date string")    
  if (parts.len mod 2) != 0:
    raise newException(ValueError, "uneven date string")
  for pairs in parts.distribute(parts.len div 2):
    let amount = pairs[0].parseInt
    if amount < 0: raise newException(ValueError, "negatives are not allowed")
    case pairs[1] 
    of "week", "weeks":
      result += initDuration(weeks = amount)
    of "day", "days":
      result += initDuration(days = amount)
    of "hour", "hours":
      result += initDuration(hours = amount)
    of "minute", "minutes":
      result += initDuration(minutes = amount)
    of "second", "seconds":
      result += initDuration(seconds = amount)
    else:
      raise newException(ValueError, "unknown date part: " & pairs[1])

when isMainModule:
  import unittest
  suite "parse duration string":
    test "unknown":
      doAssertRaises(ValueError): discard parseDuration("1 foo")
    test "no number":
      doAssertRaises(ValueError): discard parseDuration("rax days")
    test "empty":
      doAssertRaises(ValueError): discard parseDuration("")
      doAssertRaises(ValueError): discard parseDuration(" ")
    test "uneven":
      doAssertRaises(ValueError): discard parseDuration("1 days years")
    test "negatives":
      doAssertRaises(ValueError): discard parseDuration("-1 days years")      
    test "simple":
      assert parseDuration("1 second") == initDuration(seconds = 1)
      assert parseDuration("1 hour") == initDuration(hours = 1)
      assert parseDuration("1 days") == initDuration(days = 1)
      assert parseDuration("1 week") == initDuration(weeks = 1)
    test "multiple":
      assert parseDuration("1 days 12 hours") == initDuration(days = 1, hours = 12)
      assert parseDuration("1 day 12 hours 30 minutes 20 seconds") == initDuration(days = 1, hours = 12, minutes = 30, seconds = 20)