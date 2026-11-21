class_name Spawner
extends RefCounted
## Fills the shaft above the camera, one 5 m slice at a time.
## Each slice is a 4 x 3 grid; a few cells get one thing each, jittered inside
## the cell. Nothing may sit closer than (r1 + r2) x 1.25 to anything else, and
## spiky things keep 240 px away from puffers, so you never get punished for
## shooting a puffer that hides an urchin.

const SLICE := 500.0
const COLS := 4
const ROWS := 3
const LEFT := 100.0
const RIGHT := 980.0
const HAZARD_GAP := 240.0
const TRIES := 6

var next_y: float = 0.0
var start_y: float = 0.0
var _since_ammo: float = 0.0          # metres since the last ammo bubble


func _init(start: float) -> void:
	start_y = start
	next_y = start - 450.0


## Make slices until `top_y` (world) is covered.
func fill(things: Array, top_y: float) -> void:
	while next_y > top_y - 500.0:
		_slice(things)
		next_y -= SLICE


func _slice(things: Array) -> void:
	var h := (start_y - next_y) / 100.0          # metres up
	var cells := range(COLS * ROWS)
	cells.shuffle()
	var n := clampi(2 + int(h / 45.0), 2, 5) + randi() % 2
	var cw := (RIGHT - LEFT) / COLS
	var ch := SLICE / ROWS
	_since_ammo += SLICE / 100.0
	for i in mini(n, cells.size()):
		var k := _pick(h)
		if _since_ammo > 40.0 and i == 0:
			k = Kinds.AMMO                       # an ammo bubble every ~40 m at least
		if k == Kinds.AMMO:
			_since_ammo = 0.0
		var col: int = cells[i] % COLS
		var row: int = cells[i] / COLS
		for t in TRIES:
			var at := Vector2(LEFT + (col + 0.5) * cw, next_y - (row + 0.5) * ch)
			var th := Kinds.make(k, at)
			var r := Kinds.reach(th)
			th["base"] = at + Vector2(randf_range(-1, 1) * maxf(0.0, cw * 0.5 - r), randf_range(-1, 1) * maxf(0.0, ch * 0.5 - r * 0.6))
			if _fits(things, th):
				_place(things, th)
				break


## Fits if nothing can ever touch it, counting how far both drift.
func _fits(things: Array, th: Dictionary) -> bool:
	var k: int = th["k"]
	for o in things:
		var ok: int = o["k"]
		var d: float = th["base"].distance_to(o["base"])
		if d < (Kinds.reach(th) + Kinds.reach(o)) * 1.1:
			return false
		if (Kinds.spiky(k) and Kinds.puffer(ok)) or (Kinds.puffer(k) and Kinds.spiky(ok)):
			if d < HAZARD_GAP + Kinds.reach(th) + Kinds.reach(o) - 80.0:
				return false
	return true


func _place(things: Array, th: Dictionary) -> void:
	if th["k"] == Kinds.SWARMER:               # a neat triangle of three
		for i in 3:
			var s := th.duplicate()
			s["slot"] = TAU * i / 3.0
			s["p"] = s["base"]
			things.append(s)
	else:
		th["p"] = th["base"]
		things.append(th)


## What to spawn at height h (metres): more and nastier spikes higher up.
func _pick(h: float) -> int:
	var w := {
		Kinds.PUFFER: 10.0,
		Kinds.SWARMER: 3.0,
		Kinds.SHIELDED: 2.5,
		Kinds.URCHIN: 2.0 + minf(h * 0.05, 6.0),
		Kinds.CHASER: minf(h * 0.02, 3.0),
		Kinds.BOMBER: minf(h * 0.015, 2.5),
		Kinds.COIN: 4.0,
		Kinds.MEGA: 0.5,
		Kinds.AMMO: 1.2,
		Kinds.MAGNET: 0.5,
		Kinds.GOLDEN: 0.4,
	}
	var total := 0.0
	for k in w:
		if h < Kinds.FIRST_SEEN[k]:
			w[k] = 0.0
		total += w[k]
	var roll := randf() * total
	for k in w:
		roll -= w[k]
		if roll <= 0.0:
			return k
	return Kinds.PUFFER
