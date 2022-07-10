import types

type
  Offset* = uint

const
  localPlayerOffset = 0x587c0c.Offset
  playerListOffset = 0x587c10.Offset
  playerListSizeOffset = 0x58efe4.Offset

var
  localPlayer*: Player
  localPlayerPtr*: ptr Player = cast[ptr ptr Player](localPlayerOffset)[]

  playerList*: seq[Player]

proc update(_: type localPlayer) = 
  localPlayer = cast[ptr ptr Player](localPlayerOffset)[][]

proc update(_: type playerList) = 
  playerList.setLen 0

  let 
    playersBase = cast[ptr int](playerListOffset)[]
    playersCount = cast[ptr int32](playerListSizeOffset)[]

  if playersCount > 0:
    for i in 0..<playersCount:
      let ptrPlayer = cast[ptr ptr Player](playersBase + 0x4 + (i * 0x4))

      playerList.add ptrPlayer[][]

proc update* = 
  localPlayer.update
  playerList.update