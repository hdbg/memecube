import winim
import std/tables

proc write*[T](address: int, data: T) = 
  cast[ptr T](address)[] = data
proc read*[T](address: int): T =
  cast[ptr T](address)[]

let moduleBase = int GetModuleHandle(nil)

proc relWrite*[T](offset: int, data: T) = 
  cast[ptr T](moduleBase + offset)[] = data
proc relRead*[T](offset: int): T = 
  cast[ptr T](moduleBase + offset)[]

# proc ptrResolve*(addrs: varargs[int]): pointer = 
#   result = pointer(moduleBase)

#   for a in addrs:
#     result = cast[ptr pointer](result.int + a)[]

proc relative*(address: int): int = moduleBase + address

# Complex related

type OpCode = uint8

const
  nop = 0x90.OpCode
  jmp = 0xE9.OpCode
  call = 0xE8.OpCode

var nopped: Table[int, seq[OpCode]]

proc setNop*(address: int, len: int = 1) = 
  if nopped.contains(address):
    let original = nopped[address]

    for i in 0..original.len:
      let pointed = cast[ptr OpCode](address + i)

      pointed[] = original[i]

    nopped.del address
  else:
    var savedOpcodes: seq[OpCode]

    for i in 0..len:
      let pointed = cast[ptr OpCode](address + i)

      savedOpcodes.add pointed[]

      pointed[] = nop

    nopped[address] = savedOpcodes

type
  Hook* = object
    state*: bool
    stolen: seq[OpCode]

    trampoline: pointer
    original, target: pointer

proc createTramp(h: var Hook) = 
  h.trampoline = allocShared0(h.stolen.len + 5 + 5) # 5 for call, 5 for jump back

  copyMem h.trampoline, unsafeAddr h.stolen[0], len h.stolen 

  block createCall:
    let 
      callInstrAddr = cast[uint](h.trampoline) + h.stolen.len
      callTarget = cast[uint](h.target) - callInstrAddr - 5.uint

    cast[ptr OpCode](callInstrAddr)[] = call
    cast[ptr uint32](callInstrAddr + 1)[] = callTarget.uint32

  block createJump:
    let 
      jmpInstrAddr = cast[uint](h.trampoline) + h.stolen.len + 5.uint # 5 for previous call
      jmpTarget = (cast[uint](h.original) + h.stolen.len + 5) - jmpInstrAddr

    cast[ptr OpCode](jmpInstrAddr)[] = jmp
    cast[ptr uint32](jmpInstrAddr + 1)[] = jmpTarget.uint32

  var oldProtect: DWORD
  VirtualProtect(
    cast[LPVOID](h.trampoline), 
    SIZE_T(h.stolen.len + 10), 
    PAGE_EXECUTE_READWRITE, 
    unsafeAddr oldProtect
  )

template tempWrite(address: pointer, length: int, body: untyped) =
  var oldProtect: DWORD
  VirtualProtect(cast[LPVOID](address), length.SIZE_T, PAGE_EXECUTE_READWRITE, unsafeAddr oldProtect)
  body
  VirtualProtect(cast[LPVOID](address), length.SIZE_T, oldProtect, unsafeAddr oldProtect)

proc enable*(h: var Hook) =
  assert not h.state

  tempWrite(h.original, 5):
    cast[ptr OpCode](h.original)[] = jmp
    cast[ptr int32](cast[int](h.original) + 1)[] = int32(
      cast[int](h.original) - cast[int](h.target) + 5
    )

  h.state = true

proc disable*(h: var Hook) = 
  assert h.state

  tempWrite(h.original, h.stolen.len):
    copyMem h.original, unsafeAddr h.stolen[0], h.stolen.len

  h.state = false

proc initHook*(original, target: pointer, len: int = 5): Hook = 
  result = Hook(original: original, target: target, state: false)

  result.stolen.setLen len
  copyMem unsafeAddr(result.stolen[0]), original, len

  result.createTramp

  result.enable

  # for i in 0..<len:
  #   result.stolen.add cast[ptr OpCode](original + i)[]

  



