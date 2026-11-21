class_name FoeArt
## Sky Puffers (pink, flappy, harmless: bonk or shoot them) and Grim Urchins
## (spiky, glowing red, angry: don't touch). Variants: swarmer flock,
## shielded puffer, chasing urchin (purple, exhaust), boomer urchin (fuse).


static func puffer(g: Batch, th: Dictionary, t: float) -> void:
	var c: Vector2 = th["p"]
	var r: float = Kinds.R[th["k"]]
	var al: float = th["alert"]
	var fl: float = th["flash"]
	var flap := sin(t * 16.0 + th["ph"] * 3.0) * 0.45
	for sx in [-1.0, 1.0]:                              # wings
		var wc := c + Vector2(sx * r * 0.98, -r * 0.15)
		var rot: float = sx * (0.35 + flap)
		Paint.ellipse(g, wc, r * 0.5 + 3.0, r * 0.27 + 3.0, rot, Paint.INK)
		Paint.ellipse(g, wc, r * 0.5, r * 0.27, rot, Paint.PINK_LIGHT)
	g.draw_circle(c, r + 4.0, Paint.INK)
	g.draw_circle(c, r, Paint.PINK_DARK.lerp(Paint.WHITE, fl))
	g.draw_circle(c + Vector2(-2, -3), r - 3.0, Paint.PINK.lerp(Paint.WHITE, fl))
	Paint.ellipse(g, c + Vector2(-r * 0.38, -r * 0.45), r * 0.24, r * 0.14, -0.6, Paint.PINK_LIGHT)
	var ex := r * 0.3
	var ey := -r * 0.08
	if al > 0.5:                                        # alert: big eyes, "o" mouth
		for sx in [-1.0, 1.0]:
			Paint.blob(g, c + Vector2(sx * ex, ey), r * 0.17, Paint.WHITE, 2.5)
			g.draw_circle(c + Vector2(sx * ex, ey), r * 0.08, Paint.INK)
		g.draw_circle(c + Vector2(0, r * 0.3), r * 0.11, Paint.INK)
	else:                                               # idle: dot eyes, smile, blush
		for sx in [-1.0, 1.0]:
			g.draw_circle(c + Vector2(sx * ex, ey), r * 0.09, Paint.INK)
			g.draw_circle(c + Vector2(sx * r * 0.5, r * 0.15), r * 0.1, Color(1, 0.4, 0.5, 0.5))
		g.draw_arc(c + Vector2(0, r * 0.12), r * 0.16, 0.3, PI - 0.3, 8, Paint.INK, 3.0)
	if th["shield"]:                                    # shielded puffer bubble
		g.draw_circle(c, r + 16.0, Color(0.6, 0.85, 1.0, 0.25))
		g.draw_arc(c, r + 16.0, 0.0, TAU, 36, Color(0.55, 0.85, 1.0, 0.85), 4.0)
		g.draw_arc(c, r + 9.0, -2.5, -1.7, 8, Color(1, 1, 1, 0.85), 5.0)


static func urchin(g: Batch, th: Dictionary, t: float) -> void:
	var k: int = th["k"]
	var c: Vector2 = th["p"]
	var r: float = Kinds.R[k]
	var body := Color(0.27, 0.25, 0.31)
	if k == Kinds.CHASER:
		body = Color(0.4, 0.25, 0.48)
	elif k == Kinds.BOMBER:
		body = Color(0.88, 0.32, 0.16).lerp(Color(1, 0.8, 0.3), 0.5 + 0.5 * sin(t * 12.0)) if th["fuse"] > 0.0 \
			else Color(0.85, 0.33, 0.17)
	body = body.lerp(Paint.WHITE, th["flash"])
	var pulse := 0.5 + 0.5 * sin(t * 5.0 + th["ph"])
	g.draw_circle(c, r + 34.0, Color(Paint.RED_GLOW, 0.1 + 0.06 * pulse))   # danger glow
	g.draw_circle(c, r + 22.0, Color(Paint.RED_GLOW, 0.16 + 0.08 * pulse))
	if k == Kinds.CHASER:                               # exhaust puffs behind it
		for i in 3:
			var back := c + Vector2(0, r + 12.0 + i * 16.0).rotated(sin(t * 3.0 + i) * 0.4)
			g.draw_circle(back, 9.0 - i * 2.0, Color(0.7, 0.7, 0.75, 0.6 - i * 0.15))
	var spin: float = th["ph"] * (2.4 if k == Kinds.CHASER else 1.1)
	g.draw_colored_polygon(Paint.star(c, r + 19.0, r - 2.0, 10, spin), Paint.INK)
	g.draw_colored_polygon(Paint.star(c, r + 14.0, r - 4.0, 10, spin), Color(0.5, 0.48, 0.55))
	g.draw_circle(c, r + 3.0, Paint.INK)
	g.draw_circle(c, r, body)
	Paint.ellipse(g, c + Vector2(-r * 0.35, -r * 0.45), r * 0.22, r * 0.12, -0.6, Color(1, 1, 1, 0.25))
	for sx in [-1.0, 1.0]:                              # angry face
		var e := c + Vector2(sx * r * 0.32, -r * 0.02)
		Paint.ellipse(g, e, r * 0.17, r * 0.13, 0.0, Paint.WHITE)
		g.draw_circle(e + Vector2(-sx * 2.0, 1.0), r * 0.08, Paint.INK)
		g.draw_line(e + Vector2(-sx * r * 0.24, -r * 0.3), e + Vector2(sx * r * 0.18, -r * 0.14), Paint.INK, 6.0)
	g.draw_arc(c + Vector2(0, r * 0.52), r * 0.2, PI + 0.5, TAU - 0.5, 8, Paint.INK, 4.0)
	if k == Kinds.BOMBER:                               # fuse + spark
		var top := c + Vector2(0, -r - 18.0)
		g.draw_line(c + Vector2(0, -r), top, Paint.INK, 5.0)
		g.draw_colored_polygon(Paint.star(top, 13.0 + sin(t * 30.0) * 4.0, 5.0, 5, t * 9.0), Paint.GOLD)
