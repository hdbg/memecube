import winim

type OpCode* = uint8

const
  jmpOpCode = 0xE9.OpCode
  callOpCOde = 0xE8.OpCode
  nopOpCode = 0x90.OpCode

type
  Hook* = object
    state*: bool
    stolen: seq[OpCode]

    trampoline: pointer
    original, target: pointer

converter ptrToUint(x: pointer): uint =
  cast[uint](x) 

proc createTramp(h: var Hook) = 
  h.trampoline = allocShared0(h.stolen.len + 5 + 5) # 5 for call, 5 for jump back

  copyMem h.trampoline, unsafeAddr h.stolen[0], len h.stolen 

  let lenStolen = uint h.stolen.len

  block createCall:
    let 
      callInstrAddr = cast[uint](h.trampoline) + lenStolen
      callTarget = cast[uint](h.target) - callInstrAddr - lenStolen + 1

    cast[ptr OpCode](callInstrAddr)[] = callOpCOde
    cast[ptr uint32](callInstrAddr + 1)[] = callTarget.uint32

  block createJump:
    let 
      jmpInstrAddr = cast[uint](h.trampoline) + h.stolen.len.uint + 5.uint # 5 for previous call
      jmpTarget = cast[uint](h.original) - jmpInstrAddr.uint + 1

    cast[ptr OpCode](jmpInstrAddr)[] = jmpOpCode
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

  tempWrite(h.original, len h.stolen):
    for i in 0..<len(h.stolen):
      cast[ptr OpCode](h.original.ptrToUint + i.uint)[] = nopOpCode

    cast[ptr OpCode](h.original)[] = jmpOpCode
    cast[ptr uint32](h.original.ptrToUint + 1.uint)[] = uint32(
       h.trampoline.ptrToUint - h.original.ptrToUint - 5
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