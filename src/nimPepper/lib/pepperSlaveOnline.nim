import os, strutils, strformat, macros, times
import illwill
import asyncdispatch
import messages

type 
  Modes = enum
    Overview, Detail
  SlaveOnline* = ref object
    clients*: seq[ClientInfo]
    mode: Modes
    tb: TerminalBuffer
    seperator: bool
    lastRefresh: float

proc resetLastRefresh*(so: SlaveOnline) = 
  so.lastRefresh = epochTime()

proc timeFromLastRefresh(so: SlaveOnline): float = 
  epochTime() - so.lastRefresh

proc exitProc() {.noconv.} =
  illwillDeinit()
  showCursor()
  quit(0)

proc writeMenu(so: SlaveOnline) =
  so.tb.write(1, so.tb.height-1, 
    fgWhite, "Menu: ", 
    fgRed , "(1) ", fgWhite, "Overview |", 
    fgRed , "(2) ", fgWhite, "Details |",
    fgRed , "(s) ", fgWhite, "seperator |",
    fgRed , "(q) ", fgWhite, "quit |",
    fgWhite, bgBlack, "lastRefresh: ", $so.timeFromLastRefresh.int,
    resetStyle
  )

proc getLongestName(clients: seq[ClientInfo]): int =
  result = 0
  for client in clients:
    if client.name.len > result:
      result = client.name.len

proc renderOverview(so: SlaveOnline) =
  var line = 0
  for client in so.clients:
    var bg = 
      if client.online:
        bgGreen
      else:
        bgRed
    if (so.tb.getCursorXPos() + client.name.len) >= so.tb.width:
      so.tb.setCursorXPos(0)
      so.tb.setCursorYPos(so.tb.getCursorYPos() + 1)
    so.tb.write(bg, fgBlack, client.name, bgBlack, " ")
    # if so.seperator:
    #   so.tb.write(bgWhite, fgBlack, "|", resetStyle)
  so.tb.write(resetStyle)

proc renderDetail(so: SlaveOnline) = 
  var longestName = so.clients.getLongestName()
  var line = 0
  for client in so.clients:
    var bg = 
      if client.online:
        bgGreen
      else:
        bgRed
    so.tb.write(1, line,  
      fgWhite, bgBlack, if client.online: "[x]" else: "[ ]", resetStyle, " ",
      fgBlack, bg,
      client.name.alignLeft(longestName+1), 
      " (", client.ip.alignLeft(15), ") " , 
      client.publicKey,
      resetStyle
    )
    if so.seperator:
      line.inc
      so.tb.setForegroundColor(fgBlack)
      so.tb.drawHorizLine(0, so.tb.width, line)
    line.inc
  discard

proc pepperSlaveOnlineMain*(so: SlaveOnline) {.async.} =
  illwillInit(fullscreen=true)
  setControlCHook(exitProc)
  hideCursor()
  so.resetLastRefresh()
  while true:
    so.tb = newTerminalBuffer(terminalWidth(), terminalHeight())
    var key = getKey()
    case key
    of Key.One:
      so.mode = Overview
    of Key.Two:
      so.mode = Detail
    of Key.Q:
      exitProc()
    of Key.S:
      so.seperator = (not so.seperator)
    else:
      discard
    
    case so.mode
    of Overview:
      so.renderOverview()
    of Detail:
      so.renderDetail()

    so.writeMenu()
    so.tb.write(20, 20, $key)
    so.tb.display()
    await sleepAsync(50)

proc newSlaveOnline*(): SlaveOnline =
  result = SlaveOnline()
  result.mode = Overview
  result.seperator = true

when isMainModule:
  var so = newSlaveOnline()
  const testPubKey = "m+5oZuoWmtVVzlsyX4FfBJoI3LC99BzdIARYXJjm9Xs="
  so.clients = @[
    ClientInfo(name: "foo", ip: "192.168.2.199", online: true, publicKey: testPubKey),
    ClientInfo(name: "baa", ip: "192.168.2.199", online: true, publicKey: testPubKey),
    ClientInfo(name: "baz", ip: "", online: false, publicKey: testPubKey),
    ClientInfo(name: "longNameForTest", ip: "192.168.2.199", online: true, publicKey: testPubKey),
    ClientInfo(name: "fuxdiedudel", ip: "192.168.2.199", online: true, publicKey: testPubKey),
    ClientInfo(name: "peter", ip: "192.168.2.199", online: true, publicKey: testPubKey),
    ClientInfo(name: "peteasdfjasdjfklasdjfr", ip: "192.168.2.199", online: true, publicKey: testPubKey),
    ClientInfo(name: "asdfljasdlkfjlskdfjjfjjj", ip: "192.168.2.199", online: true, publicKey: testPubKey),
    ClientInfo(name: "asdfljasdlkfjlskdfjjfjjj", ip: "192.168.2.199", online: true, publicKey: testPubKey),
    ClientInfo(name: "asdfljasdlkfjlskdfjjfjjj", ip: "192.168.2.199", online: true, publicKey: testPubKey),
    ClientInfo(name: "LAST", ip: "192.168.2.199", online: true, publicKey: testPubKey)
  ]
  waitFor so.pepperSlaveOnlineMain()