import std/[options]
import types, globals

var enabled = true

proc getNearest(): Option[Player] = 
  var minDist = float.high

  for p in globals.playerList:
    let currDist = dist(p.origin, localPlayer.origin)
    if currDist < minDist:
      minDist = currDist
      result = some p

proc onTick* = 
  if not enabled: return

  # echo "Lp name: ", $localPlayer.name
  echo "Lp angles": localPlayer.view

  let nearest = getNearest()

  if nearest.isNone:
    return

  # echo "Name: ", get(nearest).name
  # echo "======="

  let aimAngles = localPlayer.playersToAngles nearest.get

  # echo aimAngles

  if aimAngles.yaw != NaN and aimAngles.pitch != NaN:
    localPlayerPtr.view = aimAngles

  