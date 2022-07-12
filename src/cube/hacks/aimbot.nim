import std/[options, math]
import types, globals

var enabled = true

proc getNearest(): Option[PlayerPtr] = 
  var minDist = float.high

  for p in globals.iterPlayers():
    let currDist = dist(p.origin, localPlayer.origin)
    if currDist < minDist:
      minDist = currDist
      result = some p

proc aimAtAngles*(src, dest: PlayerPtr): Angle2 =
  # echo "[Angles] Source: ", src, " Dest: ", dest

  let headRelative = dest.head - src.head

  result.pitch = arcsin(
    headRelative.z / headRelative.length 
  ).radToDeg

  result.yaw = ((arctan2(headRelative.y, headRelative.x).radToDeg) + 90.float32)

proc onTick* = 
  if not enabled: return

  echo "Lp angles: ", localPlayer.view

  let nearest = getNearest()

  if nearest.isSome:
    let aimAngles = localPlayer.aimAtAngles nearest.get

    if aimAngles.yaw != NaN and aimAngles.pitch != NaN:
      localPlayer.view = aimAngles

  