# import pepperslaveImports
import json, asyncdispatch
export json, asyncdispatch

type
  ## The procedure modules must implement
  SlaveCommandFunc*[T] = proc(obj: T, params: string = ""): Future[JsonNode]