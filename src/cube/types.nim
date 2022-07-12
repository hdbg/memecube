import std/[strutils, math]

type
  Vector3* {.packed.} = object
    x*, y*, z*: cfloat

  Angle2* {.packed.} = object
    yaw*, pitch*: cfloat

  PlayerState* {.packed.} = object
    vmt: pointer
    health, armor: int32
    padding1: array[0x10, uint8]

  Player* {.packed.} = object
    vmt: pointer
    head*: Vector3
    padding1: array[0x18, int8]

    origin*: Vector3
    view*: Angle2

    padding2: array[0x25, uint8]
    isCrouching*: bool

    padding3: array[0x1A2, uint8]
    isFiring*: bool
    name*: array[16, char]

  PlayerPtr* = ptr Player

# Vector based math
proc `+`*(f, s: Vector3): Vector3 = Vector3(x: (s.x + f.x), y: (s.y + f.y), z: (s.z + f.z))
proc `-`*(s, f: Vector3): Vector3 = Vector3(x: (s.x - f.x), y: (s.y - f.y), z: (s.z - f.z))
proc `*`*(f, s: Vector3): Vector3 = Vector3(x: (s.x * f.x), y: (s.y * f.y), z: (s.z * f.z))
proc `/`*(f, s: Vector3): Vector3 = Vector3(x: (s.x / f.x), y: (s.y - f.y), z: (s.z - f.z))

# Scalar math
proc `+`*(f: Vector3, s: float): Vector3 = Vector3(x: (s + f.x), y: (s + f.y), z: (s + f.z))
proc `-`*(f: Vector3, s: float): Vector3 = Vector3(x: (s - f.x), y: (s - f.y), z: (s - f.z))
proc `*`*(f: Vector3, s: float): Vector3 = Vector3(x: (s * f.x), y: (s * f.y), z: (s * f.z))
proc `/`*(f: Vector3, s: float): Vector3 = Vector3(x: (s / f.x), y: (s - f.y), z: (s - f.z))

proc dist*(f, s: Vector3): float = sqrt(pow(f.x - s.x, 2) + pow(f.y - s.y, 2) + pow(f.z - s.z, 2))
proc length*(f: Vector3): float = sqrt(f.x ^ 2 + f.y ^ 2 + f.z ^ 2)
proc normalize*(f: Vector3): Vector3 = f / f.length

# Players methods
proc `$`(x: Player): string = 
  var temp: seq[char]

  for c in x.name:
    if c == '\x00': break
    temp.add c

  temp.join("")



  # while result.yaw >= 180: result.yaw -= 180

# Debug
import std/[strformat, strutils, macros]

# static:
#   dumpAstGen:
#     type Player3* {.packed.} = object
#       vmt: pointer
#       headPos*: Vector3
#       padding1: array[0x1E, int8]

#       origin*: Vector3
#       view*: Angle2

#       padding2: array[0x20, uint8]
#       isCrouching*: bool

#       padding3: array[0x19e, uint8]
#       isFiring*: bool
#       playerName*: cstring

proc offsets(x: typedesc) = 
  let obj = default(x)

  var lastOffset = 0x0

  for name, val in obj.fieldPairs():
    let nameShadow = name
    let shadowVal = val
    echo &"[{nameShadow}] \t 0x{lastOffset} | {toHex sizeof shadowVal} bytes"
    lastOffset.inc sizeof(val)

  echo &"[{$x}] \t {toHex sizeof obj} bytes"


template offset(x: typedesc, field: untyped): int = 
  let obj = cast[ptr x](0)

  cast[int](unsafeAddr obj.field)

# macro dump(x: typedesc) = 
#   echo x.getTypeImpl 


when isMainModule:
  # echo "=====Vector====="
  # Vector3.offsets

  # echo "======Player======="
  # let playerObj = cast[ptr Player](0)
  # echo "Origin: ", offset(Player, origin).toHex

  # Player.allOffsets()

  let obj = Player()

  echo "Head: ", toHex offsetOf(Player, head)
  echo "pad1: ", toHex offsetOf(Player, padding1)
  echo "origin: ", toHex offsetOf(Player, origin)
  echo "view: ", toHex offsetOf(Player, view)
  echo "crouch: ", toHex offsetOf(Player, isCrouching)
  echo "fire: ", toHex offsetOf(Player, isFiring)
  echo "name: ", toHex offsetOf(Player, name)