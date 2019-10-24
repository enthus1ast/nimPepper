import ../../typesModule
import ../../typesPepperSlave
import ../../moduleLoader

var cmdPing*: SlaveCommandFunc[PepperSlave] = proc(obj: PepperSlave, params: string): Future[JsonNode] {.async.} =
  return %* {"outp": "pong"}

proc register*[T](modLoader: ModLoader, boundObj: T) =
  modLoader.registerCommand(boundObj, "ping", cmdPing)
