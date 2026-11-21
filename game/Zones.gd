class_name Zones
## The tower's height bands. Each has a name, sky colours and an extra:
## storm = lightning, aurora = light ribbons, black = stars. Colours blend
## over the last 30 m before the next zone.

const BLEND := 30.0
const LIST := [
	{"name": "SUNRISE DOCKS", "from": 0, "top": Color(0.98, 0.6, 0.47), "bot": Color(1.0, 0.85, 0.64),
		"far": Color(0.82, 0.42, 0.4), "mist": Color(1.0, 0.92, 0.82), "lamp": 0.25},
	{"name": "COPPER CLOUDS", "from": 100, "top": Color(0.34, 0.38, 0.68), "bot": Color(0.93, 0.56, 0.5),
		"far": Color(0.3, 0.27, 0.5), "mist": Color(1.0, 0.78, 0.72), "lamp": 0.45},
	{"name": "STORM BELT", "from": 200, "top": Color(0.12, 0.14, 0.25), "bot": Color(0.3, 0.32, 0.47),
		"far": Color(0.09, 0.1, 0.19), "mist": Color(0.62, 0.68, 0.85), "lamp": 0.8},
	{"name": "AURORA REACH", "from": 300, "top": Color(0.03, 0.09, 0.17), "bot": Color(0.06, 0.27, 0.3),
		"far": Color(0.02, 0.07, 0.13), "mist": Color(0.45, 1.0, 0.8), "lamp": 1.0},
	{"name": "THE BLACK", "from": 420, "top": Color(0.01, 0.01, 0.04), "bot": Color(0.08, 0.05, 0.17),
		"far": Color(0.03, 0.02, 0.07), "mist": Color(0.72, 0.6, 1.0), "lamp": 1.0},
]


static func index(m: float) -> int:
	var i := 0
	for z in LIST.size():
		if m >= LIST[z]["from"]:
			i = z
	return i


## A zone colour (or number) at height m, blended near the boundary.
static func get_value(m: float, key: String):
	var i := index(m)
	var here = LIST[i][key]
	if i + 1 >= LIST.size():
		return here
	var nxt: float = LIST[i + 1]["from"]
	var k := clampf((m - (nxt - BLEND)) / BLEND, 0.0, 1.0)
	if here is Color:
		return (here as Color).lerp(LIST[i + 1][key], k)
	return lerpf(here, LIST[i + 1][key], k)


## Metres left to the next zone (-1 at the top).
static func to_next(m: float) -> int:
	var i := index(m)
	return int(LIST[i + 1]["from"] - m) if i + 1 < LIST.size() else -1


## 0..1 progress through the current zone.
static func progress(m: float) -> float:
	var i := index(m)
	if i + 1 >= LIST.size():
		return 1.0
	var a: float = LIST[i]["from"]
	return clampf((m - a) / (LIST[i + 1]["from"] - a), 0.0, 1.0)
