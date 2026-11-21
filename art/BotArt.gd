class_name BotArt
## The Recoil Bot: a round brass robot with a teal band, big eyes and a
## cannon arm. Faces: idle (blinks), squint when firing or hit, sweat drop
## on low ammo, X eyes when out. Jet flame when shooting up fast.


static func draw(g: Batch, pl: Player, t: float, dead: bool) -> void:
	var c := pl.p
	var r := 36.0
	var base := g.get_xf()
	g.scale_around(c, Player.ART * (1.0 + 0.14 * maxf(0.0, 1.0 - pl.fire_t * 9.0)))   # pop on each shot
	var aim := pl.aim
	if pl.v.y < -500.0 and not dead:                  # jet flame under him
		var f := 1.0 + sin(t * 40.0) * 0.2
		g.draw_colored_polygon(PackedVector2Array([c + Vector2(-14, r - 4), c + Vector2(14, r - 4),
			c + Vector2(0, r + 46 * f)]), Color(1.0, 0.6, 0.15))
		g.draw_colored_polygon(PackedVector2Array([c + Vector2(-7, r - 4), c + Vector2(7, r - 4),
			c + Vector2(0, r + 26 * f)]), Color(1.0, 0.95, 0.5))
	if pl.shield > 0 and not dead:                    # shield bubble
		g.draw_circle(c, r + 24.0, Color(0.55, 0.85, 1.0, 0.22))
		g.draw_arc(c, r + 24.0, 0.0, TAU, 40, Color(0.5, 0.85, 1.0, 0.8), 4.0)
		g.draw_arc(c, r + 16.0, -2.4, -1.6, 10, Color(1, 1, 1, 0.8), 5.0)
	if pl.inv > 0.0 and not dead:                     # hurt: flicker, never vanish
		g.alpha = 0.35 if int(pl.inv / 0.06) % 2 == 0 else 1.0
	# Ear pads
	for sx in [-1.0, 1.0]:
		Paint.blob(g, c + Vector2(sx * (r - 1.0), -2.0), 9.0, Paint.TEAL, 3.0)
	# Body: dark rim, brass, highlight
	g.draw_circle(c, r + 5.0, Paint.INK)
	g.draw_circle(c, r, Paint.BRASS_DARK)
	g.draw_circle(c + Vector2(-3, -4), r - 4.0, Paint.BRASS)
	Paint.ellipse(g, c + Vector2(-r * 0.4, -r * 0.52), r * 0.3, r * 0.16, -0.5, Paint.BRASS_LIGHT)
	# Teal band with rivets
	var by := 11.0
	var hw := sqrt(r * r - by * by)
	g.draw_line(c + Vector2(-hw, by), c + Vector2(hw, by), Paint.TEAL, 12.0)
	g.draw_line(c + Vector2(-hw, by + 5.0), c + Vector2(hw, by + 5.0), Paint.TEAL_DARK, 3.0)
	for i in 3:
		g.draw_circle(c + Vector2(-14.0 + i * 14.0, by), 2.6, Paint.TEAL_DARK)
	_face(g, c, pl, t, dead)
	# Cannon arm (points where you shot)
	var root := c + aim * (r - 8.0)
	var tip := c + aim * (r + 30.0)
	g.draw_line(root, tip, Paint.INK, 28.0)
	g.draw_line(root, tip, Paint.BRASS, 19.0)
	g.draw_line(root + aim.orthogonal() * 5.0, tip + aim.orthogonal() * 5.0, Paint.BRASS_LIGHT, 4.0)
	Paint.blob(g, tip, 12.0, Paint.BRASS_DARK, 3.0)
	g.draw_circle(tip, 6.5, Paint.INK)
	if pl.fire_t < 0.08:                              # muzzle flash
		g.draw_colored_polygon(Paint.star(tip + aim * 22.0, 30.0, 12.0, 5, t * 20.0), Color(1, 0.85, 0.3))
	g.alpha = 1.0
	g.set_xf(base)


static func _face(g: Batch, c: Vector2, pl: Player, t: float, dead: bool) -> void:
	var ey := -10.0
	var low := pl.ammo <= 1
	if dead:                                           # X X
		for sx in [-1.0, 1.0]:
			var e := c + Vector2(sx * 12.0, ey)
			g.draw_line(e + Vector2(-7, -7), e + Vector2(7, 7), Paint.INK, 4.0)
			g.draw_line(e + Vector2(7, -7), e + Vector2(-7, 7), Paint.INK, 4.0)
		Paint.drop(g, c + Vector2(30, -26), 7.0, Color(0.5, 0.8, 1.0))
		return
	var squint := pl.fire_t < 0.12 or pl.hurt_t < 0.4
	var blink := fmod(t, 3.2) < 0.12
	for sx in [-1.0, 1.0]:
		var e := c + Vector2(sx * 12.0, ey)
		if squint:                                     # > <
			g.draw_line(e + Vector2(-sx * 7, -6), e + Vector2(sx * 5, 0), Paint.INK, 4.0)
			g.draw_line(e + Vector2(sx * 5, 0), e + Vector2(-sx * 7, 6), Paint.INK, 4.0)
		elif blink:
			g.draw_line(e + Vector2(-8, 0), e + Vector2(8, 0), Paint.INK, 4.0)
		else:
			Paint.blob(g, e, 10.0, Paint.WHITE, 3.0)
			g.draw_circle(e + pl.aim * 3.5, 5.5, Paint.INK)
			g.draw_circle(e + pl.aim * 3.5 + Vector2(-2, -2), 1.8, Paint.WHITE)
	if low:                                            # sweat drop: almost out
		Paint.drop(g, c + Vector2(30, -26), 7.0, Color(0.5, 0.8, 1.0))


## Drone buddy: a little brass ball with one eye and a buzzing rotor.
static func drone(g: Batch, at: Vector2, t: float) -> void:
	var base := g.get_xf()
	g.scale_around(at, Player.ART)
	var w := sin(t * 60.0) * 14.0
	g.draw_line(at + Vector2(-w, -20), at + Vector2(w, -20), Paint.INK, 3.0)
	g.draw_line(at + Vector2(0, -14), at + Vector2(0, -20), Paint.INK, 3.0)
	Paint.blob(g, at, 14.0, Paint.BRASS, 3.0)
	Paint.blob(g, at + Vector2(0, -1), 6.0, Paint.TEAL, 2.0)
	g.draw_circle(at + Vector2(0, -1), 2.5, Paint.INK)
	g.set_xf(base)
