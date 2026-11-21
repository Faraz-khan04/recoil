class_name Widgets
## UI building blocks: rounded shapes, glass pills, beveled buttons, text,
## and little icons for coins and the five upgrades.


static func rounded(g: Batch, r: Rect2, col: Color, rad: float = 28.0) -> void:
	rad = minf(rad, minf(r.size.x, r.size.y) * 0.5)
	var pts := PackedVector2Array()
	var cs := [r.end - Vector2(rad, rad), Vector2(r.position.x + rad, r.end.y - rad),
		r.position + Vector2(rad, rad), Vector2(r.end.x - rad, r.position.y + rad)]
	for i in 4:
		for j in 7:
			pts.append(cs[i] + Vector2.from_angle(PI * 0.5 * i + PI * 0.5 * j / 6.0) * rad)
	g.draw_colored_polygon(pts, col)


## Dark see-through panel with a faint rim: HUD backgrounds.
static func pill(g: Batch, r: Rect2) -> void:
	rounded(g, r.grow(3.0), Color(1, 1, 1, 0.16), r.size.y * 0.5 + 3.0)
	rounded(g, r, Paint.GLASS, r.size.y * 0.5)


## Chunky button: drop shadow, body, light top half, ink rim.
static func button(g: Batch, r: Rect2, text: String, col: Color, on: bool = true, size: int = 0) -> void:
	if not on:
		col = col.lerp(Color(0.55, 0.53, 0.58), 0.65)
	var rad := minf(30.0, r.size.y * 0.35)
	rounded(g, Rect2(r.position + Vector2(0, 10), r.size), col.darkened(0.45), rad)
	rounded(g, r.grow(4.0), Paint.INK, rad + 4.0)
	rounded(g, r, col, rad)
	rounded(g, Rect2(r.position + Vector2(10, 7), Vector2(r.size.x - 20, r.size.y * 0.42)), Color(1, 1, 1, 0.22), rad * 0.7)
	if text != "":
		Fx.label(g, text, r.get_center(), size if size > 0 else int(clampf(r.size.y * 0.42, 28, 64)),
			Paint.WHITE if on else Color(1, 1, 1, 0.7), true)


static func text_left(g: Batch, t: String, at: Vector2, size: int, col: Color, outline: bool = false,
		font: Font = null) -> void:
	var f := font if font else ThemeDB.fallback_font
	if outline:
		var o := maxf(2.0, size / 16.0)
		for d in [Vector2(-o, 0), Vector2(o, 0), Vector2(0, -o), Vector2(0, o), Vector2(o * 0.7, o * 1.4)]:
			g.draw_string(f, at + d, t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(Paint.INK, col.a))
	g.draw_string(f, at, t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


static func coin(g: Batch, c: Vector2, r: float) -> void:
	Paint.blob(g, c, r, Paint.GOLD_DARK, maxf(2.0, r * 0.15))
	g.draw_circle(c + Vector2(-1, -1), r * 0.78, Paint.GOLD)
	g.draw_colored_polygon(Paint.star(c, r * 0.5, r * 0.22, 5), Paint.GOLD_DARK)


static func heart(g: Batch, c: Vector2, r: float, col: Color, ink: bool = true) -> void:
	for pass_i in (2 if ink else 1):
		var s := r + (4.0 if pass_i == 0 and ink else 0.0)
		var cc := Paint.INK if pass_i == 0 and ink else col
		g.draw_circle(c + Vector2(-s * 0.5, -s * 0.2), s * 0.55, cc)
		g.draw_circle(c + Vector2(s * 0.5, -s * 0.2), s * 0.55, cc)
		g.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 1.03, -s * 0.05), c + Vector2(s * 1.03, -s * 0.05),
			c + Vector2(0, s * 0.95)]), cc)
	g.draw_circle(c + Vector2(-r * 0.45, -r * 0.35), r * 0.18, Color(1, 1, 1, 0.5))


## The five upgrade icons, in a round badge.
static func upgrade_icon(g: Batch, key: String, c: Vector2, r: float) -> void:
	Paint.blob(g, c, r, Color(0.2, 0.17, 0.26), 4.0)
	match key:
		"clip":
			for i in 3:
				Paint.bullet(g, c + Vector2((i - 1) * r * 0.42, 0), r * 0.62, Vector2.UP, Paint.BRASS)
		"shield":
			g.draw_circle(c, r * 0.62, Color(0.55, 0.85, 1.0, 0.45))
			g.draw_arc(c, r * 0.62, 0.0, TAU, 24, Color(0.6, 0.9, 1.0), 5.0)
			g.draw_arc(c, r * 0.42, -2.5, -1.6, 6, Color(1, 1, 1, 0.9), 4.0)
		"boost":
			g.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.32, -r * 0.2), c + Vector2(r * 0.32, -r * 0.2),
				c + Vector2(0, r * 0.7)]), Color(1.0, 0.55, 0.15))
			g.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.16, -r * 0.2), c + Vector2(r * 0.16, -r * 0.2),
				c + Vector2(0, r * 0.38)]), Color(1.0, 0.95, 0.5))
			Paint.blob(g, c + Vector2(0, -r * 0.35), r * 0.3, Paint.BRASS, 3.0)
		"drone":
			Paint.blob(g, c + Vector2(0, r * 0.1), r * 0.38, Paint.BRASS, 3.0)
			g.draw_circle(c + Vector2(0, r * 0.1), r * 0.15, Paint.TEAL)
			g.draw_line(c + Vector2(-r * 0.5, -r * 0.45), c + Vector2(r * 0.5, -r * 0.45), Paint.WHITE, 4.0)
		"magnet":
			var pts := PackedVector2Array([c + Vector2(r * 0.4, -r * 0.45)])
			for i in 9:
				pts.append(c + Vector2.from_angle(PI * i / 8.0) * r * 0.4)
			pts.append(c + Vector2(-r * 0.4, -r * 0.45))
			g.draw_polyline(pts, Color(0.92, 0.25, 0.3), r * 0.26)
			for sx in [-1.0, 1.0]:
				g.draw_line(c + Vector2(sx * r * 0.4, -r * 0.5), c + Vector2(sx * r * 0.4, -r * 0.3), Paint.WHITE, r * 0.26)
