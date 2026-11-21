class_name Look
## Draws a frame, back to front: sky + parallax (Sky), wall shading, height
## marks, launch pad, everything in the shaft, shots, drone, the bot,
## effects, tower walls (Tower), floating text, dust, speed lines, danger
## glow, HUD, screens.

const W := 1080.0
const H := 2400.0


static func draw(game: RecoilGame) -> void:
	var g := Batch.new(game)
	var w := game.world
	var m := maxf(0.0, (RecoilGame.START.y - (game.cam + 1150.0)) / 100.0)   # height at screen middle
	SkyArt.draw(g, game.cam, m, game.t)
	Tower.shade(g)
	g.draw_set_transform(Vector2(0, -game.cam) + game.fx.offset())
	_marks(g, game.cam)
	_pad(g, RecoilGame.START.y + 70.0)
	for th in w.things:
		if Kinds.puffer(th["k"]):
			FoeArt.puffer(g, th, game.t)
		elif Kinds.spiky(th["k"]):
			FoeArt.urchin(g, th, game.t)
		else:
			LootArt.draw(g, th, game.t)
	for sh in w.shots:
		var col := Paint.GOLD if sh["gold"] else Color(1, 0.75, 0.25)
		g.draw_line(sh["p"] - sh["v"] * 0.03, sh["p"], Color(col, 0.35), 18.0)
		g.draw_line(sh["p"] - sh["v"] * 0.025, sh["p"], Paint.INK, 13.0)
		g.draw_line(sh["p"] - sh["v"] * 0.025, sh["p"], col, 7.0)
	if Save.level("drone") > 0:
		BotArt.drone(g, Extras.drone_pos(w), game.t)
	BotArt.draw(g, w.pl, game.t, game.state == RecoilGame.State.DEAD)
	game.fx.draw(g)
	Tower.walls(g, game.cam, Zones.get_value(m, "lamp"), game.t)
	game.fx.draw_text(g)
	g.draw_set_transform(Vector2.ZERO)
	SkyArt.motes(g, game.cam, game.t)
	if game.state == RecoilGame.State.PLAY:
		Tower.speed_lines(g, game.cam, clampf((-w.pl.v.y - 1200.0) / 800.0, 0.0, 1.0))
		Tower.danger(g, clampf((w.pl.p.y - game.cam - 1750.0) / 450.0, 0.0, 1.0))
	Hud.draw(g, game)
	Screens.draw(g, game)
	g.flush()


static func _marks(g: Batch, cam: float) -> void:
	var first := int(floor(cam / 500.0)) * 500
	for y in range(first, int(cam + H) + 500, 500):
		var m := int((RecoilGame.START.y - y) / 100.0)
		if m <= 0:
			continue
		g.draw_line(Vector2(64, y), Vector2(W - 64, y), Color(1, 1, 1, 0.1), 3.0)
		Widgets.text_left(g, "%d m" % m, Vector2(84, y - 12), 28, Color(1, 1, 1, 0.45), false, Paint.body())


## The launch pad you start on: slate block, brass rim, hazard stripes.
static func _pad(g: Batch, y: float) -> void:
	g.draw_rect(Rect2(0, y, W, 700), Color(0.29, 0.31, 0.38))
	g.draw_rect(Rect2(0, y, W, 16), Paint.BRASS_LIGHT)
	g.draw_rect(Rect2(0, y + 16, W, 10), Paint.BRASS_DARK)
	for i in 14:
		var x := i * 90.0
		g.draw_colored_polygon(PackedVector2Array([Vector2(x, y + 40), Vector2(x + 45, y + 40),
			Vector2(x + 15, y + 90), Vector2(x - 30, y + 90)]), Paint.GOLD)
	g.draw_rect(Rect2(0, y + 26, W, 14), Color(0.2, 0.21, 0.26))
