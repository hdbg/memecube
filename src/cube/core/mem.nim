import std/[segfaults, options]
import winim

type GenericAddress = uint | pointer | int

proc get*[T: GenericAddress, Y](obj: typedesc[Y], address: T): ptr Y = cast[ptr Y](address)
proc get*[T: GenericAddress, Y](obj: typedesc[Y], address: T, depth: int): ptr Y =
  var last: pointer = cast[pointer](address)
  for _ in 1..<depth:
    last = cast[ptr pointer](last)[]

  result = cast[ptr Y](last)


# WIP
proc sigScan(pattern: string, address: GenericAddress, module: Option[string]): Option[pointer] =
  let modBase = GetModuleHandleA(if module.isNone: 0.NULL else: module.get)

