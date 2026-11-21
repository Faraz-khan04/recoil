class_name Fx
extends RefCounted
## Juice shared by all prototypes: particles, screen shake, floating text,
## slow motion. Call update(delta) every frame, draw(g) inside the batch,
## draw_text(g) last. Pure arrays, no nodes, so hundreds of bits stay cheap.

const MAX := 400

var trauma: float = 0.0
var slow: float = 1.0                 # game speed multiplier (slow motion)
var _slow_t: float = 0.0
var _p := PackedVector2Array()
var _v := PackedVector2Array()
var _life := PackedFloat32Array()
var _max := PackedFloat32Array()
var _size := PackedFloat32Array()
var _col: Array[Color] = []
var _texts: Array = []                # [text, pos, life, color, size]


func _init() -> void:
	_p.resize(MAX); _v.resize(MAX); _life.resize(MAX); _max.resize(MAX); _size.resize(MAX)
	_col.resize(MAX)


## A burst of n bits flying out of `at`.
func burst(at: Vector2, col: Color, n: int, speed: float = 600.0, size: float = 10.0) -> void:
	for k in n:
		var i := _free()
		_p[i] = at
		_v[i] = Vector2.from_angle(randf() * TAU) * speed * randf_range(0.3, 1.0)
		_max[i] = randf_range(0.3, 0.7)
		_life[i] = _max[i]
		_size[i] = size * randf_range(0.6, 1.3)
		_col[i] = col


func shake(amount: float) -> void:
	trauma = minf(1.0, trauma + amount)


## Floating text. If it would land on another label, it stacks above it.
func text(t: String, at: Vector2, col: Color, size: int = 48) -> void:
	var p := at
	for i in 6:
		var clash := false
		for o in _texts:
			if absf(o[1].x - p.x) < 260.0 and absf(o[1].y - p.y) < size * 0.95:
				clash = true
				break
		if not clash:
			break
		p.y -= size * 1.05
	_texts.append([t, p + Vector2(randf_range(-16.0, 16.0), 0.0), 0.9, col, size])


## Slow motion for `secs` of real time.
func slowmo(secs: float, scale: float = 0.25) -> void:
	_slow_t = secs
	slow = scale


func offset() -> Vector2:
	var s := trauma * trauma * 30.0
	return Vector2(randf_range(-s, s), randf_range(-s, s))


func update(delta: float) -> void:
	trauma = maxf(0.0, trauma - delta * 1.8)
	if _slow_t > 0.0:
		_slow_t -= delta
		if _slow_t <= 0.0:
			slow = 1.0
	var d := delta * slow
	for i in MAX:
		if _life[i] > 0.0:
			_life[i] -= d
			_v[i] *= exp(-3.0 * d)
			_p[i] += _v[i] * d
	for t in _texts:
		t[2] -= delta
		t[1] += Vector2(0.0, -90.0 * delta)
	_texts = _texts.filter(func(t): return t[2] > 0.0)


func draw(g: Batch) -> void:
	for i in MAX:
		if _life[i] > 0.0:
			var k := _life[i] / _max[i]
			var s := _size[i] * k
			g.draw_rect(Rect2(_p[i] - Vector2(s, s) * 0.5, Vector2(s, s)), _col[i])


func draw_text(g: Batch) -> void:
	for t in _texts:
		var c: Color = t[3]
		c.a = minf(1.0, t[2] * 3.0)
		Fx.label(g, t[0], t[1], t[4], c, true)


## Centred outlined text (outline = 4 offset copies, cheap and readable).
static func label(g: Batch, t: String, at: Vector2, size: int, col: Color, outline: bool = false,
		font: Font = null) -> void:
	var f := font if font else ThemeDB.fallback_font
	var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	at.x = clampf(at.x, w * 0.5 + 70.0, 1010.0 - w * 0.5)     # never off the screen edge
	var p := at - Vector2(w * 0.5, -size * 0.35)
	if outline:
		var ink := Color(0.1, 0.09, 0.12, col.a)
		var o4 := maxf(2.0, size / 16.0)
		for o in [Vector2(-o4, 0), Vector2(o4, 0), Vector2(0, -o4), Vector2(0, o4), Vector2(o4 * 0.7, o4 * 1.4)]:
			g.draw_string(f, p + o, t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, ink)
	g.draw_string(f, p, t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


func _free() -> int:
	for i in MAX:
		if _life[i] <= 0.0:
			return i
	return randi() % MAX
