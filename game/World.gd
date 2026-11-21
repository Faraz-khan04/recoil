class_name World
extends RefCounted
## One run: the things in the shaft, the shots, and what happens on contact.
##   Puffers: bonk (+1 ammo, bounce if you land on one) or shoot (+2).
##   Urchins hurt; 2 shots to pop. Boomers explode in chains. Shots ricochet once.

const SHOT_SPEED := 2600.0
const SHOT_HIT := 22.0               # generous hit radius
const H := 2400.0

var things: Array = []
var shots: Array = []                # {p, v, life, bounce, gold, drone}
var pl: Player
var fx: Fx
var spawner: Spawner
var coins: int = 0                   # this run (banked on death, whatever the cause)
var combo: int = 0
var magnet_t: float = 0.0
var golden_t: float = 0.0
var died: bool = false
var drone_ang: float = 0.0
var _combo_t: float = 0.0
var drone_t: float = 1.0


func _init(f: Fx) -> void:
	fx = f
	pl = Player.new()
	spawner = Spawner.new(pl.p.y)


func fire(target: Vector2) -> bool:
	var gold := golden_t > 0.0
	if not pl.shoot(target, gold):
		return false
	shots.append({"p": pl.p + pl.aim * 72.0, "v": pl.aim * SHOT_SPEED, "life": 0.9, "bounce": 1,
		"gold": gold, "drone": false})
	return true


## Tap with an empty clip: a puff of steam nudges you sideways, away from
## the tap (no lift), so you can steer a fall into a puffer or ammo bubble.
func nudge(target: Vector2) -> void:
	var dir := signf(pl.p.x - target.x) if absf(pl.p.x - target.x) > 4.0 else 1.0
	pl.v.x = clampf(pl.v.x + dir * 300.0, -650.0, 650.0)
	pl.aim = (target - pl.p).normalized()
	fx.burst(pl.p + pl.aim * 60.0, Color(0.9, 0.92, 0.95, 0.8), 8, 260.0, 18.0)


func step(d: float, cam: float) -> void:
	pl.step(d)
	spawner.fill(things, cam)
	magnet_t = maxf(0.0, magnet_t - d)
	golden_t = maxf(0.0, golden_t - d)
	_combo_t -= d
	if _combo_t <= 0.0:
		combo = 0
	# Shop MAGNET = bigger passive coin pull. SUPER MAGNET pickup = 5 s pull of
	# every coin AND ammo bubble on screen. Anything within 110 px slides in.
	var pull: float = [80.0, 160.0, 250.0, 350.0][mini(Save.level("magnet"), 3)]
	var grab := 110.0
	if magnet_t > 0.0:
		pull = 1500.0
		grab = 1500.0
	for th in things:
		Motion.move(th, pl.p, d, pull, grab)
		if th["hp"] > 0 and th["p"].distance_to(pl.p) < Kinds.R[th["k"]] + Player.R * 0.9:
			_touch(th)
		if th["fuse"] > 0.0:
			th["fuse"] -= d
			if th["fuse"] <= 0.0:
				_explode(th)
	_move_shots(d)
	Extras.drone(self, d)
	things = things.filter(func(t): return t["hp"] > 0 and t["p"].y < cam + H + 400.0)


func _touch(th: Dictionary) -> void:
	var k: int = th["k"]
	if Kinds.puffer(k):
		if th["shield"]:                         # bubble: you bounce off it
			pl.v = (pl.p - th["p"]).normalized() * 800.0
			th["flash"] = 1.0
			Sfx.play("click", 0.6)
			return
		if pl.v.y > 0.0 and pl.p.y < th["p"].y:  # landed on it: stomp bounce
			pl.v.y = -1100.0
		_pop(th, false)
	elif Kinds.spiky(k):
		if k == Kinds.BOMBER:
			_explode(th)
			return
		var away: Vector2 = (pl.p - th["p"]).normalized()
		if pl.inv <= 0.0:                        # pop out of the spikes first
			pl.p = th["p"] + away * (Kinds.R[k] + Player.R + 10.0)
		_hurt(th["p"])
	else:
		Extras.collect(self, th)


func _hurt(from: Vector2) -> void:
	var had_shield := pl.shield > 0
	if pl.inv > 0.0:
		return
	died = pl.hurt(from) or died
	fx.shake(0.8)
	fx.slowmo(0.18, 0.2)
	fx.burst(pl.p, Color(1, 0.3, 0.3) if not had_shield else Color(0.4, 0.8, 1.0), 20, 800.0)
	fx.text("SHIELD!" if had_shield else "OUCH!", pl.p + Vector2(0, -80), Color(1, 0.4, 0.4), 56)
	Sfx.play("lose", 2.0, -4.0)


func _move_shots(d: float) -> void:
	for s in shots:
		s["p"] += s["v"] * d
		s["life"] -= d
		if s["p"].x < Player.WALL or s["p"].x > Player.W - Player.WALL:
			if s["bounce"] > 0:                  # ricochet off the pipes
				s["bounce"] -= 1
				s["v"].x = -s["v"].x
				s["p"].x = clampf(s["p"].x, Player.WALL, Player.W - Player.WALL)
			else:
				s["life"] = 0.0
		for th in things:
			if s["life"] <= 0.0:
				break
			if th["hp"] > 0 and s["p"].distance_to(th["p"]) < SHOT_HIT + Kinds.R[th["k"]]:
				_shot_hits(th, s)
	shots = shots.filter(func(s): return s["life"] > 0.0)


func _shot_hits(th: Dictionary, s: Dictionary) -> void:
	var k: int = th["k"]
	if not s["gold"]:
		s["life"] = 0.0                          # golden shots go straight through
	th["flash"] = 1.0
	if Kinds.puffer(k) and th["shield"]:
		th["shield"] = false
		Sfx.play("shield")
		fx.burst(th["p"], Color(0.7, 0.9, 1.0), 16, 600.0)
	elif Kinds.puffer(k):
		_pop(th, true)
	elif Kinds.spiky(k):
		th["hp"] -= 2 if s["gold"] else 1
		Sfx.play("hit")
		if th["hp"] <= 0:
			if k == Kinds.BOMBER:
				th["hp"] = 1
				_explode(th)
			else:
				_reward(th, true)
				fx.burst(th["p"], Color(0.25, 0.22, 0.3), 24, 900.0, 14.0)
	else:
		Extras.collect(self, th)


func _pop(th: Dictionary, shot: bool) -> void:
	th["hp"] = 0
	_reward(th, shot)
	fx.burst(th["p"], Color(1.0, 0.55, 0.75), 18, 800.0, 14.0)
	fx.burst(th["p"], Color(1, 1, 1), 6, 500.0, 8.0)
	Sfx.play("kill", 1.1 + combo * 0.07)


## Ammo + coins for a kill, and the combo.
func _reward(th: Dictionary, shot: bool) -> void:
	var k: int = th["k"]
	th["hp"] = 0
	var a: int = Kinds.AMMO_SHOT[k] if shot else Kinds.AMMO_BONK[k]
	pl.refill(a)
	coins += Kinds.COINS[k]
	combo += 1
	_combo_t = 1.4
	var label := "+%d AMMO" % a if combo < 2 else "x%d COMBO  +%d" % [combo, a]
	fx.text(label, th["p"], Color(1, 0.85, 0.3), 44 + mini(combo, 8) * 3)
	fx.shake(0.15)
	if combo >= 3:
		fx.slowmo(0.25, 0.35)


func _explode(th: Dictionary) -> void:
	th["hp"] = 0
	th["fuse"] = -1.0
	var at: Vector2 = th["p"]
	_reward(th, true)
	fx.burst(at, Color(1.0, 0.55, 0.15), 50, 1700.0, 22.0)
	fx.shake(0.9)
	fx.slowmo(0.3, 0.3)
	Sfx.play("boom")
	for o in things:
		if o["hp"] > 0 and o["p"].distance_to(at) < 230.0:
			if o["k"] == Kinds.BOMBER and o["fuse"] < 0.0:
				o["fuse"] = 0.15                 # chain reaction
			elif Kinds.puffer(o["k"]):
				_pop(o, true)
			elif Kinds.spiky(o["k"]) and o["k"] != Kinds.BOMBER:
				_reward(o, true)
	if pl.p.distance_to(at) < 170.0:
		_hurt(at)
