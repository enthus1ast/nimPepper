when defined windows:
  import winim
elif defined posix:
  import posix

proc hostname*(): string = 
  ## returns the computername
  let len = 1024
  when defined windows:
    var cstr = cast[LPSTR](alloc(len))
    var dlen: DWORD = len.int32
    discard GetComputerNameA(cstr,  addr dlen)
    return $cstr
  elif defined posix:
    var cstr = cast[cstring](alloc(len))
    discard gethostname(cstr, len)
    return $cstr

when isMainModule:
  echo hostname()