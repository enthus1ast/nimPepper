# cp installation.exe /home/david/vmshare/
# vboxmanage guestcontrol windows7 run --username peter --password 123poipoi --exe "Z:/installation.exe" --wait-stdout
import winregistry

var
  faceName: string
  fontSize: int32
  fontWeight: int32
  h: RegHandle

try:
  h = open("HKEY_CURRENT_USER\\Console\\Git Bash", samRead)
  faceName = h.readString("FaceName")
  fontSize = h.readInt32("FontSize")
  fontWeight = h.readInt32("FontWeight")
  echo faceName
  echo fontSize
  echo fontWeight
except RegistryError:
  echo "err: ", getCurrentExceptionMsg()
finally:
  close(h)

proc install*(master: string, port: uint16, pubKey: string, autostart = false): bool =
  discard
  echo "foo"