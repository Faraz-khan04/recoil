class_name LootArt
## Spinning coins, mega coin with a star, green ammo bubble, magnet,
## golden ammo.


static func draw(g: Batch, th: Dictionary, t: float) -> void:
	var k: int = th["k"]
	var c: Vector2 = th["p"]
	var r: float = Kinds.R[k]
	match k:
		Kinds.COIN, Kinds.MEGA:
			var sx := maxf(absf(cos(t * 3.0 + th["ph"])), 0.18)
			if k == Kinds.MEGA:
				g.draw_circle(c, r + 18.0, Color(1, 0.9, 0.4, 0.25 + 0.1 * sin(t * 6.0)))
			Paint.ellipse(g, c, r * sx + 4.0, r + 4.0, 0.0, Paint.INK)
			Paint.ellipse(g, c, r * sx, r, 0.0, Paint.GOLD_DARK)
			Paint.ellipse(g, c + Vector2(-1, -1), (r - 5.0) * sx, r - 5.0, 0.0, Paint.GOLD)
			if sx > 0.55:
				if k == Kinds.MEGA:
					g.draw_colored_polygon(Paint.star(c, r * 0.55 * sx, r * 0.25 * sx, 5), Paint.GOLD_DARK)
				else:
					Fx.label(g, "$", c + Vector2(0, -1), int(r * 1.2), Paint.GOLD_DARK)
		Kinds.AMMO:
			g.draw_circle(c, r + 10.0, Color(Paint.GREEN, 0.18 + 0.08 * sin(t * 5.0)))
			g.draw_circle(c, r, Color(Paint.GREEN, 0.35))
			g.draw_arc(c, r, 0.0, TAU, 32, Color(0.25, 0.75, 0.4), 5.0)
			Paint.bullet(g, c, r * 0.75, Vector2(1, -1), Paint.BRASS)
			g.draw_arc(c, r - 8.0, -2.6, -1.8, 8, Color(1, 1, 1, 0.9), 5.0)
		Kinds.MAGNET:
			var pts := PackedVector2Array()
			for i in 13:
				pts.append(c + Vector2.from_angle(PI * i / 12.0) * r * 0.55)
			pts.insert(0, c + Vector2(r * 0.55, -r * 0.6))
			pts.append(c + Vector2(-r * 0.55, -r * 0.6))
			g.draw_polyline(pts, Paint.INK, 24.0)
			g.draw_polyline(pts, Color(0.9, 0.2, 0.25), 16.0)
			for sx in [-1.0, 1.0]:
				g.draw_line(c + Vector2(sx * r * 0.55, -r * 0.6), c + Vector2(sx * r * 0.55, -r * 0.3), Color(0.85, 0.85, 0.9), 16.0)
		Kinds.GOLDEN:
			g.draw_circle(c, r + 14.0, Color(1, 0.85, 0.3, 0.3 + 0.15 * sin(t * 8.0)))
			Paint.blob(g, c, r, Paint.GOLD, 4.0)
			Paint.bullet(g, c, r * 0.7, Vector2(1, -1), Paint.BRASS_LIGHT)
