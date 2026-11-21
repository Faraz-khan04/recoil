class_name Player
extends RefCounted
## The Recoil Bot: position, speed, ammo, hearts, shield, and the kick.
## Kick rule: shooting down while falling CANCELS the fall first (instant pop
## upward) instead of adding to it, so a shot always saves you.

const R := 42.0
const ART := 1.3                     # the art is drawn for R 32, then scaled
const GRAVITY := 2500.0
const KICK := 1450.0
const WALL := 64.0                   # tower walls are this thick
const W := 1080.0

var p := Vector2(540, 1700)
var v := Vector2.ZERO
var aim := Vector2.DOWN
var ammo: int = 6
var clip: int = 6
var hearts: int = 3
var shield: int = 0
var inv: float = 0.0                 # can't be hurt again yet
var fire_t: float = 9.0              # time since last shot (muzzle flash, face)
var hurt_t: float = 9.0
var flying: bool = false             # gravity starts with the first shot


func _init() -> void:
	clip = 6 + Save.level("clip")
	ammo = clip
	shield = Save.level("shield")


## Shoot toward `target` (world). Returns false when out of ammo.
func shoot(target: Vector2, free_shot: bool = false) -> bool:
	if ammo <= 0 and not free_shot:
		return false
	aim = (target - p).normalized()
	if not free_shot:
		ammo -= 1
	var kick := -aim * KICK * (1.0 + 0.08 * Save.level("boost"))
	if kick.y < 0.0 and v.y > 0.0:
		v.y = kick.y                     # snappy: falling is cancelled, then the pop
		v.x = v.x * 0.4 + kick.x
	else:
		v = v * 0.35 + kick
	flying = true
	fire_t = 0.0
	return true


func step(d: float) -> void:
	inv = maxf(0.0, inv - d)
	fire_t += d
	hurt_t += d
	if flying:
		v.y += GRAVITY * d
	v.x *= exp(-1.2 * d)
	p += v * d
	if p.x < WALL + R and v.x < 0.0:     # side walls bounce you back in
		p.x = WALL + R
		v.x = -v.x * 0.6
	elif p.x > W - WALL - R and v.x > 0.0:
		p.x = W - WALL - R
		v.x = -v.x * 0.6


## A spiky thing touched you. Returns true if that was the last heart.
## Knockback always throws you UP and away, never down into the pit.
func hurt(from: Vector2) -> bool:
	if inv > 0.0:
		return false
	inv = 1.2
	hurt_t = 0.0
	# Always up and toward the middle of the shaft: a hit (or shield) never
	# pins you to the wall or drops you into the pit.
	var to_middle := signf(W * 0.5 - p.x) if absf(W * 0.5 - p.x) > 20.0 else signf(p.x - from.x)
	v = Vector2(to_middle * 420.0, -1150.0)
	if shield > 0:
		shield -= 1
		Sfx.play("shield")
		return false
	hearts -= 1
	return hearts <= 0


func refill(n: int) -> void:
	ammo = mini(clip + 2, ammo + n)
