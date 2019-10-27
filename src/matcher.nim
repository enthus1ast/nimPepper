import parseopt
import sequtils
import strtabs
export strtabs
import strutils

template getOrDefault(arr: typed, idx: int, default = ""): string =
  if arr.len <= idx:
    default
  else:
    arr[idx].key

proc match*(input, pattern: string, matches: StringTableRef): bool =
  matches.clear(modeCaseSensitive)
  var inputP = initOptParser(input)
  var patternP = initOptParser(pattern)
  var inputSeq = toSeq(inputP.getopt())
  var patternSeq =toSeq(patternP.getopt())
  if inputSeq.len > patternSeq.len: return false
  for idx in 0..patternSeq.len-1:
    let curI = $inputSeq.getOrDefault(idx)
    let curP = $patternSeq[idx].key
    if curP.startsWith("{") and curP.endswith("}"):
      matches[curP.strip(chars ={'{','}'})] = curI
    # elif curP.startsWith("[") and curP.endswith("]"):
    #   matches[curP.strip(chars ={'{','}'})] = curI
    else:
      if curI != curP: return false
  return true

when isMainModule:
  import unittest
  suite "matcher":
    test "match; no capture":
      var matches = newStringTable()
      assert match("A B C", "A B C", matches)
      assert matches.len == 0
    test "no match; no capture; but more input":
      var matches = newStringTable()
      assert false == match("A B C D", "A B C", matches)
      assert matches.len == 0      
    test "no match; no capture":
      var matches = newStringTable()
      assert false == match("A B C", "A B QQ", matches)
      assert matches.len == 0
    test "match; capture":
      var matches = newStringTable()
      assert true == match("A B C", "A B {some}", matches)
      assert matches.len == 1
      assert matches["some"] == "C"
    test "match; only capture":
      var matches = newStringTable()
      assert true == match("A B C", "{some1} {some2} {some3}", matches)
      assert matches.len == 3
      assert matches["some1"] == "A"
      assert matches["some2"] == "B"
      assert matches["some3"] == "C"
    test "match; more comples matches":
      var matches = newStringTable()
      assert true == match("""A "ich bin da" C""", "A {some} C", matches)
      assert matches.len == 1
      assert matches["some"] == "ich bin da"
    test "match; with optional; caputre but empty":
      var matches = newStringTable()
      assert true == match("A B C", "A B C {optional}", matches)
      assert matches.len == 1