import types
import core/mem

import std/sequtils

type
  Offset* = uint

const
  localPlayerOffset = 0x587c0c.Offset
  playerListOffset = 0x587c10.Offset
  playerListSizeOffset = 0x58efe4.Offset

var
  localPlayer* = Player.get(localPlayerOffset, depth=2)

  
iterator iterPlayers*(): ptr Player = 
  let 
    playersBase = cast[ptr int](playerListOffset)[]
    playersCount = cast[ptr int32](playerListSizeOffset)[]

  if playersCount > 0:
    for i in 0..<playersCount:
      let ptrPlayer = cast[ptr ptr Player](playersBase + 0x4 + (i * 0x4))

      yield ptrPlayer[]

proc getPlayers*(): seq[ptr Player] = toSeq(iterPlayers())