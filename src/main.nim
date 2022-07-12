import winim/lean
# import chronicles

import cube/[types, globals]
import cube/core/[hook, mem]
import std/[segfaults, os, options, strutils]

import cube/hacks/[aimbot]


proc CheatMain() = 
  AllocConsole()

  # reload stdout
  proc freopen_s(stream: ptr File, filename, mode: cstring, outStream: File): cint {.nodecl, importc, header: "stdio.h".}
  discard freopen_s(cast[ptr File](stdout), "CONOUT$", "w", stdout)

  echo "attached"

  defer: echo "exception"

  while true:
    20.sleep

    aimbot.onTick()

proc getCurrentModule: HINSTANCE =
  discard GetModuleHandleEx(
    GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS or
    GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
    cast[LPWSTR](getCurrentModule),
    result.addr,
  )

DisableThreadLibraryCalls(getCurrentModule())
CloseHandle CreateThread(cast[LPSECURITY_ATTRIBUTES](nil), 0.SIZE_T, cast[LPTHREAD_START_ROUTINE](CheatMain), cast[LPVOID](nil), 0, nil) 
