import winim

import helpers

type OpCode* = uint8

const
  jmpOpCode = 0xE9.OpCode
  callOpCOde = 0xE8.OpCode
  nopOpCode = 0x90.OpCode

  jmpEncoded = 5

type
  Hook*[T: proc] = ref object
    state*: bool
    stolen: seq[OpCode]

    trampoline*: T
    original, target: T




proc init*[T](_: type Hook, original, target: T, size: uint = 5): Hook[T] = 
  new result

  # create trampoline
  result.stolen.setLen(size)
  result.trampoline = cast[T](allocShared0(size + 5))

  var oldProtect: int32
  assert VirtualProtect(cast[LPVOID](result.trampoline), int32(size + 5), PAGE_EXECUTE_READWRITE, addr oldProtect) == TRUE

  copyMem(addr result.stolen[0], original, size)
  copyMem(result.trampoline, original, size)

  var goBackAddr: pointer = cast[pointer](cast[uint](result.trampoline) + size)

  cast[ptr OpCode](goBackAddr)[] = jmpOpCode
  cast[ptr int](cast[int](goBackAddr) + 1)[] = (cast[int](original) + size.int) - cast[int](goBackAddr) - 5

  # modify original
  tempWrite(original, size.int):
    cast[ptr OpCode](original)[] = jmpOpCode
    cast[ptr int](cast[int](original) + 1)[] = cast[int](target) - cast[int](original) - 5

    if size > 5:
      for b in countup(cast[uint](original) + 5.uint, cast[uint](original) + size):
         cast[ptr OpCode](b)[] = nopOpCode

  result