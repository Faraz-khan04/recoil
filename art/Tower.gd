class_name Tower
## The tower's inner walls (what you bounce off): riveted brass panels with
## porthole lamps whose warm light spills into the shaft (brighter in dark
## zones). Plus side shading, the low-danger red glow, and speed lines.

const W := 1080.0
const H := 2400.0
const PANEL := 240.0


static func walls(g: Batch, cam: float, lamp: float, t: float) -> void:
	var w := Player.WALL
	var first := int(floor(cam / PANEL))
	for i in range(first, first + int(H / PANEL) + 2):
		var y := i * PANEL
		var lit := i % 3 == 0
		if lit:                                       # lamp glow into the shaft
			var flick := 0.9 + 0.1 * sin(t * 7.0 + i)
			for side in [w + 6.0, W - w - 6.0]:
				g.draw_circle(Vector2(side, y + PANEL * 0.5), 120.0, Color(1, 0.75, 0.4, 0.1 * lamp * flick))
				g.draw_circle(Vector2(side, y + PANEL * 0.5), 60.0, Color(1, 0.8, 0.5, 0.14 * lamp * flick))
		for x0 in [0.0, W - w]:
			g.draw_rect(Rect2(x0, y, w, PANEL), Paint.BRASS_DARK)
			g.draw_rect(Rect2(x0 + 5, y + 5, w - 10, PANEL - 10), Paint.BRASS)
			g.draw_rect(Rect2(x0 + 5, y + 5, w - 10, 6), Paint.BRASS_LIGHT)         # bevel top
			g.draw_rect(Rect2(x0 + 5, y + PANEL - 11, w - 10, 6), Color(0.45, 0.32, 0.15))
			for ry in [y + 18.0, y + PANEL - 18.0]:
				for rx in [x0 + 15.0, x0 + w - 15.0]:
					g.draw_circle(Vector2(rx, ry), 4.0, Paint.BRASS_DARK)
					g.draw_circle(Vector2(rx - 1, ry - 1), 2.0, Paint.BRASS_LIGHT)
			if lit:                                   # porthole lamp
				var c := Vector2(x0 + w * 0.5, y + PANEL * 0.5)
				g.draw_circle(c, 22.0, Paint.INK)
				g.draw_circle(c, 17.0, Color(1, 0.82, 0.45).lerp(Color(1, 0.95, 0.75), lamp))
				g.draw_circle(c + Vector2(-5, -5), 5.0, Color(1, 1, 1, 0.8))
	for x0 in [w - 4.0, W - w]:                       # dark inner trim
		g.draw_rect(Rect2(x0, cam, 4.0, H), Paint.INK)


## Darker toward both walls, so the middle of the shaft reads clearly.
static func shade(g: Batch) -> void:
	var w := Player.WALL
	var dark := Color(0.05, 0.03, 0.08, 0.28)
	var clear := Color(0.05, 0.03, 0.08, 0.0)
	g.draw_polygon(PackedVector2Array([Vector2(w, 0), Vector2(w + 150, 0), Vector2(w + 150, H), Vector2(w, H)]),
		PackedColorArray([dark, clear, clear, dark]))
	g.draw_polygon(PackedVector2Array([Vector2(W - w - 150, 0), Vector2(W - w, 0), Vector2(W - w, H), Vector2(W - w - 150, H)]),
		PackedColorArray([clear, dark, dark, clear]))


## Red glow rising from the bottom when you're close to falling out.
static func danger(g: Batch, k: float) -> void:
	if k <= 0.0:
		return
	var red := Color(1.0, 0.15, 0.15, 0.45 * k)
	var clear := Color(1.0, 0.15, 0.15, 0.0)
	g.draw_polygon(PackedVector2Array([Vector2(0, H - 520), Vector2(W, H - 520), Vector2(W, H), Vector2(0, H)]),
		PackedColorArray([clear, clear, red, red]))


## Streaks rushing past when you rocket upward.
static func speed_lines(g: Batch, cam: float, k: float) -> void:
	if k <= 0.0:
		return
	for i in 14:
		var x := 120.0 + SkyArt._hash(i, 20.0) * (W - 240.0)
		var y := fposmod(SkyArt._hash(i, 21.0) * H - cam * 2.2, H + 400.0) - 200.0
		g.draw_line(Vector2(x, y), Vector2(x, y + 160.0 + 120.0 * k), Color(1, 1, 1, 0.22 * k), 5.0)
