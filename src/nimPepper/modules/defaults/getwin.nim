import winlean

type
  USHORT = uint16
  WCHAR = distinct int16
  UCHAR = uint8
  NTSTATUS = int32

type OSVersionInfoExW {.importc: "OSVERSIONINFOEXW", header: "<windows.h>".} = object
  dwOSVersionInfoSize: ULONG
  dwMajorVersion: ULONG
  dwMinorVersion: ULONG
  dwBuildNumber: ULONG
  dwPlatformId: ULONG
  szCSDVersion: array[128, WCHAR]
  wServicePackMajor: USHORT
  wServicePackMinor: USHORT
  wSuiteMask: USHORT
  wProductType: UCHAR
  wReserved: UCHAR

proc `$`(a: array[128, WCHAR]): string = $cast[WideCString](unsafeAddr a[0])

proc rtlGetVersion(lpVersionInformation: var OSVersionInfoExW): NTSTATUS
  {.cdecl, importc: "RtlGetVersion", dynlib: "ntdll.dll".}

type WindowsVersion {.pure.} = enum
  winxp,
  winvista,
  win7,
  win8,
  win81,
  win10

proc getWinVer*(): WindowsVersion =
  var vi: OSVersionInfoExW
  discard rtlGetVersion(vi)
  if vi.dwMajorVersion == 5  and vi.dwMinorVersion == 1: return WindowsVersion.winxp
  if vi.dwMajorVersion == 6  and vi.dwMinorVersion == 0: return WindowsVersion.winvista
  if vi.dwMajorVersion == 6  and vi.dwMinorVersion == 1: return WindowsVersion.win7
  if vi.dwMajorVersion == 6  and vi.dwMinorVersion == 2: return WindowsVersion.win8
  if vi.dwMajorVersion == 6  and vi.dwMinorVersion == 3: return WindowsVersion.win81
  if vi.dwMajorVersion == 6  and vi.dwMinorVersion == 4: return WindowsVersion.win10
  if vi.dwMajorVersion == 10  and vi.dwMinorVersion == 0: return WindowsVersion.win10

when isMainModule:
  echo getWinVer()