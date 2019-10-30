import typesPepperd
import pepperdImports

proc masterHandleLog*(pepperd: Pepperd) {.async.} = 
  discard
  # perform validation
  # write to given logfile/folder
  # [optional] call log file handler

  # create logResp
  #   fill in the id from the old msg
  # answer with logResp

proc masterHandlePing*(pepperd: Pepperd) {.async.} = 
  discard
  # perform validation
  # [optional] call ping handler

  # create pingResp
  #   fill in the id from the old msg
  # answer with pingResp

proc masterHandleControlRes*(pepperd: Pepperd) {.async.} = 
  discard
  # perform validation
  # [optional] call controlRes handler

  # mark/delete outstanding waitlist entry
