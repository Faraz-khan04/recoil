class_name Kinds
## Everything that floats in the shaft.
##   Puffers are friendly-ish: bonk them with your body or shoot them for ammo.
##   Urchins hurt on touch. Loot is grabbed by touching or shooting it.

enum { PUFFER, SWARMER, SHIELDED, URCHIN, CHASER, BOMBER, COIN, MEGA, AMMO, MAGNET, GOLDEN }

const R := [56.0, 30.0, 60.0, 52.0, 52.0, 54.0, 34.0, 50.0, 46.0, 44.0, 44.0]
const HP := [1, 1, 1, 2, 2, 1, 1, 1, 1, 1, 1]
const AMMO_SHOT := [2, 1, 2, 2, 2, 3, 0, 0, 0, 0, 0]   # bullets back when shot
const AMMO_BONK := [1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0]   # bullets back when bonked
const COINS := [1, 0, 2, 2, 2, 3, 1, 10, 0, 0, 0]
const NAME := ["PUFFER", "SWARMER", "SHIELDED PUFFER", "URCHIN", "CHASER", "BOOMER",
	"COIN", "MEGA COIN", "AMMO", "SUPER MAGNET", "GOLDEN AMMO"]
const FLOCK_R := 46.0                 # swarmers sit on a triangle this far from its centre
const FIRST_SEEN := [0, 30, 45, 10, 60, 110, 0, 25, 0, 35, 70]   # metres before it appears


static func puffer(k: int) -> bool:
	return k <= SHIELDED


static func spiky(k: int) -> bool:
	return k >= URCHIN and k <= BOMBER


static func loot(k: int) -> bool:
	return k >= COIN


static func make(k: int, at: Vector2) -> Dictionary:
	var dx := 0.0                                     # how far it drifts sideways
	if k == PUFFER or k == SHIELDED: dx = randf_range(20.0, 90.0)
	elif k == URCHIN or k == BOMBER: dx = randf_range(10.0, 45.0)
	return {"k": k, "p": at, "base": at, "hp": HP[k], "ph": randf() * TAU, "dx": dx, "slot": 0.0,
		"shield": k == SHIELDED, "alert": 0.0, "fuse": -1.0, "flash": 0.0}


## Furthest it can ever reach from its home spot (size + drift + formation).
static func reach(th: Dictionary) -> float:
	var k: int = th["k"]
	return R[k] + th["dx"] + (FLOCK_R + 40.0 if k == SWARMER else 0.0) + (12.0 if puffer(k) else 0.0)
