class_name RecoilGame
extends Node2D
## RECOIL: your gun is your jetpack. Tap anywhere: the bot shoots there and
## the kick throws it the other way. Climb the shaft; bonk or shoot pink
## puffers for ammo, avoid spiky urchins, don't fall off the bottom.
## States: READY (title) -> PLAY -> DEAD (results, revive, upgrades) -> PLAY.
## Every death goes through _game_over(), which always banks the coins.
## Desktop: R = wipe save.

enum State { READY, PLAY, DEAD }
const H := 2400.0
const START := Vector2(540, 1700)
const DEAD_LOCK := 0.9               # taps ignored this long after dying

var state: State = State.READY
var fx := Fx.new()
var world: World
var cam: float = 0.0                 # world y at the top of the screen
var peak: int = 0
var t: float = 0.0
var dead_t: float = 0.0
var cause: String = ""
var revived: bool = false
var new_best: bool = false
var _banked: int = 0
var _empty_said: float = -9.0
var zone_i: int = 0                  # zone you're in (banner when it changes)
var banner_t: float = 0.0


func _ready() -> void:
	Paint.setup_fonts()
	_new_run()


func _new_run() -> void:
	world = World.new(fx)
	cam = START.y - 1150.0 - 500.0
	peak = 0
	zone_i = 0
	banner_t = 0.0
	revived = false
	new_best = false
	_banked = 0
	world.spawner.fill(world.things, cam)


func height() -> int:
	return maxi(0, int((START.y - world.pl.p.y) / 100.0))


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and e.keycode == KEY_R:
		Save.wipe()
	if not (e is InputEventScreenTouch and e.pressed):
		return
	var at: Vector2 = e.position
	match state:
		State.READY:
			state = State.PLAY
			_tap(at)
		State.PLAY:
			_tap(at)
		State.DEAD:
			if dead_t >= DEAD_LOCK:
				_button(Screens.hit(self, at))


func _tap(screen: Vector2) -> void:
	if not world.fire(screen + Vector2(0, cam)):
		world.nudge(screen + Vector2(0, cam))      # steam puff: steer while falling
		Sfx.play("click")
		if t - _empty_said > 0.8:
			_empty_said = t
			fx.text("EMPTY!", world.pl.p + Vector2(0, -90), Color(0.95, 0.3, 0.3), 46)
		return
	fx.shake(0.12)
	fx.burst(world.pl.p + world.pl.aim * 70.0, Color(1, 0.8, 0.3), 6, 500.0, 10.0)
	Sfx.play("shoot", 0.9 + world.pl.ammo * 0.04)


func _button(id: String) -> void:
	match id:
		"play":
			_new_run()
			state = State.READY
		"revive":                                # the rewarded-ad slot (free for now)
			revived = true
			var pl := world.pl
			pl.hearts = maxi(pl.hearts, 1)
			pl.inv = 2.0
			pl.p = Vector2(540, cam + 1500.0)
			pl.v = Vector2(0, -1900)
			pl.ammo = maxi(pl.ammo, pl.clip)
			for th in world.things:              # clear spikes near the revive spot
				if Kinds.spiky(th["k"]) and th["p"].distance_to(pl.p) < 500.0:
					th["hp"] = 0
			world.died = false
			state = State.PLAY
			Sfx.play("win")
		"":
			pass
		_:
			if Save.buy(id):
				Sfx.play("coin", 0.8)
				fx.text("UPGRADED!", Vector2(540, cam + 1200), Color(0.4, 0.95, 0.5), 60)
			else:
				Sfx.play("click")


func _process(delta: float) -> void:
	t += delta
	fx.update(delta)
	queue_redraw()
	match state:
		State.PLAY:
			var d := delta * fx.slow
			world.step(d, cam)
			cam = minf(cam, world.pl.p.y - 1150.0)       # camera only goes up
			peak = maxi(peak, height())
			banner_t = maxf(0.0, banner_t - delta)
			if Zones.index(peak) > zone_i:
				zone_i = Zones.index(peak)
				banner_t = 2.6
				Sfx.play("win", 0.8)
			if world.died:
				_game_over("OUT OF HEARTS")
			elif world.pl.p.y > cam + H + 80.0:
				_game_over("FELL OFF")
		State.DEAD:
			dead_t += delta
		State.READY:
			world.pl.fire_t += delta


## The ONE way a run ends (falling or hearts): bank coins, save best.
func _game_over(why: String) -> void:
	state = State.DEAD
	dead_t = 0.0
	cause = why
	Save.coins += world.coins - _banked
	_banked = world.coins
	new_best = peak > Save.best
	Save.best = maxi(Save.best, peak)
	Save.write()
	fx.shake(0.6)
	Sfx.play("lose")


func _draw() -> void:
	Look.draw(self)
