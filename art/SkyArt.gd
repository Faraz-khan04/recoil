class_name SkyArt
## The view out of the tower, back to front, each layer slower than the
## shaft (parallax): zone gradient, stars, giant turning gears, girder
## lattice by the walls, drifting mist bands, storm lightning / aurora,
## and floating dust in front.

const W := 1080.0
const H := 2400.0


static func draw(g: Batch, cam: float, m: float, t: float) -> void:
	var top: Color = Zones.get_value(m, "top")
	var bot: Color = Zones.get_value(m, "bot")
	var far: Color = Zones.get_value(m, "far")
	var mist: Color = Zones.get_value(m, "mist")
	var zone := Zones.index(m)
	g.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, H), Vector2(0, H)]),
		PackedColorArray([top, top, bot, bot]))
	if zone >= 2:
		_stars(g, cam, t, 0.35 if zone == 2 else 1.0)
	if zone == 3:
		_aurora(g, t)
	_gears(g, cam, t, far)
	_lattice(g, cam, far)
	_mist(g, cam, t, mist)
	if zone == 2:
		_lightning(g, t)


static func _hash(i: int, salt: float) -> float:
	return fmod(absf(sin(i * 12.9898 + salt * 78.233) * 43758.5453), 1.0)


static func _stars(g: Batch, cam: float, t: float, a: float) -> void:
	var par := cam * 0.08
	for i in 70:
		var x := _hash(i, 1.0) * W
		var y := fposmod(_hash(i, 2.0) * H * 1.3 - par, H)
		var tw := 0.5 + 0.5 * sin(t * (1.0 + _hash(i, 3.0) * 3.0) + i)
		g.draw_circle(Vector2(x, y), 1.5 + _hash(i, 4.0) * 2.5, Color(1, 1, 1, a * (0.3 + 0.6 * tw)))


## Huge slow gears far away: the tower's machinery.
static func _gears(g: Batch, cam: float, t: float, col: Color) -> void:
	var par := cam * 0.15
	var band := 1100.0
	var first := int(floor(par / band)) - 1
	for i in range(first, first + 4):
		var left := _hash(i, 5.0) < 0.5
		var r := 230.0 + _hash(i, 6.0) * 140.0
		var c := Vector2(-40.0 + r * 0.35 if left else W + 40.0 - r * 0.35, i * band - par + _hash(i, 7.0) * 400.0)
		var spin := t * 0.06 * (1.0 if i % 2 == 0 else -1.0)
		var fill := Color(col, 0.55)
		g.draw_colored_polygon(Paint.star(c, r, r * 0.86, 18, spin), fill)
		g.draw_circle(c, r * 0.72, fill)
		for s in 6:                                   # spokes over a lighter hub ring
			var d := Vector2.from_angle(spin + TAU * s / 6.0)
			g.draw_line(c + d * r * 0.2, c + d * r * 0.66, Color(col.lightened(0.12), 0.5), r * 0.07)
		g.draw_circle(c, r * 0.2, Color(col.lightened(0.15), 0.6))


## Criss-cross girders near both walls.
static func _lattice(g: Batch, cam: float, col: Color) -> void:
	var par := cam * 0.45
	var step := 300.0
	var c := Color(col, 0.35)
	var off := fposmod(-par, step)
	for side in [[70.0, 190.0], [W - 190.0, W - 70.0]]:
		var a: float = side[0]
		var b: float = side[1]
		g.draw_line(Vector2(a, 0), Vector2(a, H), c, 10.0)
		g.draw_line(Vector2(b, 0), Vector2(b, H), c, 10.0)
		var y := off - step
		while y < H + step:
			g.draw_line(Vector2(a, y), Vector2(b, y + step), c, 7.0)
			g.draw_line(Vector2(b, y), Vector2(a, y + step), c, 7.0)
			g.draw_line(Vector2(a, y), Vector2(b, y), c, 9.0)
			y += step


## Soft bands of mist drifting sideways (instead of cartoon clouds).
static func _mist(g: Batch, cam: float, t: float, col: Color) -> void:
	var par := cam * 0.7
	var band := 520.0
	var first := int(floor(par / band)) - 1
	for i in range(first, first + 7):
		var y := i * band - par + _hash(i, 8.0) * 200.0
		var x := fposmod(_hash(i, 9.0) * W + t * (12.0 + _hash(i, 10.0) * 20.0), W + 600.0) - 300.0
		var w := 260.0 + _hash(i, 11.0) * 220.0
		Paint.ellipse(g, Vector2(x, y), w, 46.0, 0.0, Color(col, 0.13))
		Paint.ellipse(g, Vector2(x + w * 0.3, y - 24.0), w * 0.6, 34.0, 0.0, Color(col, 0.1))


static func _aurora(g: Batch, t: float) -> void:
	for band in 3:
		var pts := PackedVector2Array()
		for i in 25:
			var x := i * W / 24.0
			pts.append(Vector2(x, 380.0 + band * 170.0 + sin(x * 0.006 + t * 0.5 + band) * 90.0))
		g.draw_polyline(pts, Color(0.35, 1.0, 0.7, 0.1), 90.0)
		g.draw_polyline(pts, Color(0.5, 1.0, 0.85, 0.12), 26.0)


## Storm: a flash and a jagged bolt every few seconds.
static func _lightning(g: Batch, t: float) -> void:
	var cycle := fmod(t, 4.3)
	if cycle > 0.22:
		return
	var seed_i := int(t / 4.3)
	g.draw_rect(Rect2(0, 0, W, H), Color(1, 1, 1, 0.22 * (1.0 - cycle / 0.22)))
	var p := Vector2(200.0 + _hash(seed_i, 12.0) * 680.0, 0.0)
	var pts := PackedVector2Array([p])
	for i in 9:
		p += Vector2((_hash(seed_i * 10 + i, 13.0) - 0.5) * 160.0, 110.0)
		pts.append(p)
	g.draw_polyline(pts, Color(0.85, 0.9, 1.0, 0.8), 6.0)


## Dust motes in front, drifting up slowly.
static func motes(g: Batch, cam: float, t: float) -> void:
	for i in 26:
		var x := _hash(i, 14.0) * W + sin(t * 0.7 + i) * 20.0
		var y := fposmod(_hash(i, 15.0) * H - cam * 1.15 - t * 30.0, H)
		g.draw_circle(Vector2(x, y), 2.0 + _hash(i, 16.0) * 3.0, Color(1, 0.95, 0.85, 0.25))
