extends Node
## Saved between runs: total coins (kept no matter how a run ends), best
## height, upgrade levels. One small JSON file in user://.

const PATH := "user://recoil_save.json"
const UPGRADES := {
	"clip":   {"name": "BIGGER CLIP", "info": "+1 bullet", "costs": [30, 90, 220]},
	"shield": {"name": "SHIELD", "info": "blocks a hit, every run", "costs": [60, 160, 400]},
	"boost":  {"name": "BOOST", "info": "stronger kick", "costs": [40, 120, 300]},
	"drone":  {"name": "DRONE BUDDY", "info": "pops puffers for you", "costs": [120, 280, 650]},
	"magnet": {"name": "MAGNET", "info": "pulls coins in", "costs": [25, 80, 200]},
}

var coins: int = 0
var best: int = 0
var levels := {}


func _ready() -> void:
	for k in UPGRADES:
		levels[k] = 0
	if FileAccess.file_exists(PATH):
		var d = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if d is Dictionary:
			coins = int(d.get("coins", 0))
			best = int(d.get("best", 0))
			var lv = d.get("levels", {})
			if lv is Dictionary:
				for k in lv:
					if levels.has(k):
						levels[k] = int(lv[k])


func level(key: String) -> int:
	return int(levels.get(key, 0))


func cost(key: String) -> int:
	var c: Array = UPGRADES[key]["costs"]
	return c[level(key)] if level(key) < c.size() else -1      # -1 = maxed


func buy(key: String) -> bool:
	var c := cost(key)
	if c < 0 or coins < c:
		return false
	coins -= c
	levels[key] = level(key) + 1
	write()
	return true


func write() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"coins": coins, "best": best, "levels": levels}))


func wipe() -> void:
	coins = 0
	best = 0
	for k in levels:
		levels[k] = 0
	write()
