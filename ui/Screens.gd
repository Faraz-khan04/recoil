class_name Screens
## Title screen and the results screen (height, coins, revive, upgrade shop,
## fly again). hit() turns a tap into a button id for RecoilGame._button().

const W := 1080.0
const H := 2400.0
const PANEL := Rect2(56, 250, W - 112, 2080)
const REVIVE := Rect2(170, 830, 740, 130)
const PLAY := Rect2(170, 2130, 740, 150)
const ROW_Y := 1110.0
const ROW_H := 190.0


static func draw(g: Batch, game: RecoilGame) -> void:
	if game.state == RecoilGame.State.READY:
		_title(g, game)
	elif game.state == RecoilGame.State.DEAD:
		_results(g, game)


static func _title(g: Batch, game: RecoilGame) -> void:
	var dark := Color(0.06, 0.03, 0.08, 0.55)
	g.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, 900), Vector2(0, 900)]),
		PackedColorArray([dark, dark, Color(dark, 0.0), Color(dark, 0.0)]))
	var y := 470.0 + sin(game.t * 1.6) * 8.0
	Fx.label(g, "RECOIL", Vector2(W * 0.5, y + 12), 230, Paint.BRASS_DARK, true)    # chunky brass logo
	Fx.label(g, "RECOIL", Vector2(W * 0.5, y), 230, Paint.BRASS_LIGHT, false)
	Fx.label(g, "RECOIL", Vector2(W * 0.5, y - 4), 230, Color(1, 0.93, 0.7, 0.35), false)
	Widgets.rounded(g, Rect2(W * 0.5 - 300, y + 120, 600, 74), Paint.GLASS, 37.0)
	Fx.label(g, "your gun is your jetpack", Vector2(W * 0.5, y + 157), 40, Paint.WHITE, false, Paint.body())
	var pulse := 1.0 + sin(game.t * 5.0) * 0.04
	var r := Rect2(W * 0.5 - 330 * pulse, 1150, 660 * pulse, 130)
	Widgets.button(g, r, "TAP TO LAUNCH", Color(0.95, 0.45, 0.3))
	Fx.label(g, "tap below the bot to fly up", Vector2(W * 0.5, 1350), 38, Paint.WHITE, true, Paint.body())
	_tip(g, Vector2(W * 0.5, 1420), "bonk or shoot", Paint.PINK, "puffers for bullets")
	_tip(g, Vector2(W * 0.5, 1480), "never touch", Color(1, 0.5, 0.5), "spiky urchins")
	Widgets.pill(g, Rect2(150, 2210, 360, 84))
	Fx.label(g, "BEST %d m" % Save.best, Vector2(330, 2252), 44, Paint.WHITE, true)
	Widgets.pill(g, Rect2(570, 2210, 360, 84))
	Widgets.coin(g, Vector2(630, 2252), 24.0)
	Fx.label(g, str(Save.coins), Vector2(770, 2252), 44, Paint.WHITE, true)


static func _tip(g: Batch, at: Vector2, a: String, col: Color, b: String) -> void:
	var f := Paint.body()
	var wa := f.get_string_size(a + " ", HORIZONTAL_ALIGNMENT_LEFT, -1, 36).x
	var wb := f.get_string_size(b, HORIZONTAL_ALIGNMENT_LEFT, -1, 36).x
	var x := at.x - (wa + wb) * 0.5
	Widgets.text_left(g, a + " ", Vector2(x, at.y), 36, col, true, f)
	Widgets.text_left(g, b, Vector2(x + wa, at.y), 36, Paint.WHITE, true, f)


static func _results(g: Batch, game: RecoilGame) -> void:
	var a := clampf(game.dead_t / 0.35, 0.0, 1.0)
	g.draw_rect(Rect2(0, 0, W, H), Color(0.04, 0.02, 0.07, 0.65 * a))
	if game.dead_t < 0.25:
		return
	g.alpha = clampf((game.dead_t - 0.25) / 0.25, 0.0, 1.0)
	var slide := (1.0 - g.alpha) * 80.0
	var p := Rect2(PANEL.position + Vector2(0, slide), PANEL.size)
	Widgets.rounded(g, p.grow(8.0), Paint.BRASS_DARK, 50.0)
	Widgets.rounded(g, p.grow(3.0), Paint.BRASS, 46.0)
	Widgets.rounded(g, p, Color(0.11, 0.08, 0.15), 44.0)
	var top := p.position.y
	Widgets.rounded(g, Rect2(W * 0.5 - 200, top - 36, 400, 76), Color(0.85, 0.27, 0.33), 38.0)
	Fx.label(g, game.cause, Vector2(W * 0.5, top + 2), 40, Paint.WHITE, true)
	if game.new_best:                                   # gold burst behind a new best
		g.draw_colored_polygon(Paint.star(Vector2(W * 0.5, top + 230), 230.0, 150.0, 14, game.t * 0.4), Color(1, 0.8, 0.25, 0.18))
	Fx.label(g, "%d m" % game.peak, Vector2(W * 0.5, top + 220), 170, Paint.WHITE, true)
	var best := "NEW BEST!" if game.new_best else "BEST %d m" % Save.best
	Fx.label(g, best, Vector2(W * 0.5, top + 350), 50, Paint.GOLD if game.new_best else Color(1, 1, 1, 0.55), game.new_best)
	Widgets.coin(g, Vector2(W * 0.5 - 220, top + 440), 26.0)
	Fx.label(g, "+%d   ·   total %d" % [game.world.coins, Save.coins], Vector2(W * 0.5 + 20, top + 440), 44, Paint.WHITE, false)
	var ready := game.dead_t >= RecoilGame.DEAD_LOCK
	if not game.revived:
		var r := Rect2(REVIVE.position + Vector2(0, slide), REVIVE.size)
		Widgets.button(g, r, "", Color(0.3, 0.75, 0.42), ready)
		g.draw_colored_polygon(PackedVector2Array([r.position + Vector2(70, 38), r.position + Vector2(70, 92),
			r.position + Vector2(116, 65)]), Paint.WHITE)
		Fx.label(g, "REVIVE", r.get_center() + Vector2(10, -14), 54, Paint.WHITE, true)
		Fx.label(g, "watch a short ad", r.get_center() + Vector2(10, 34), 28, Color(1, 1, 1, 0.85), false, Paint.body())
	Fx.label(g, "UPGRADES", Vector2(W * 0.5, ROW_Y - 60 + slide), 50, Paint.BRASS_LIGHT, true)
	var i := 0
	for key in Save.UPGRADES:
		_row(g, key, ROW_Y + i * ROW_H + slide, ready)
		i += 1
	Widgets.button(g, Rect2(PLAY.position + Vector2(0, slide), PLAY.size), "FLY AGAIN", Color(0.95, 0.45, 0.3), ready, 66)
	g.alpha = 1.0


static func _row(g: Batch, key: String, y: float, ready: bool) -> void:
	var u: Dictionary = Save.UPGRADES[key]
	var lv := Save.level(key)
	var cost := Save.cost(key)
	Widgets.rounded(g, Rect2(100, y, W - 200, ROW_H - 22), Color(1, 1, 1, 0.06), 30.0)
	Widgets.upgrade_icon(g, key, Vector2(180, y + 84), 52.0)
	Widgets.text_left(g, u["name"], Vector2(258, y + 72), 44, Paint.WHITE)
	Widgets.text_left(g, u["info"], Vector2(258, y + 116), 30, Color(1, 1, 1, 0.6), false, Paint.body())
	for p in u["costs"].size():                         # level pips
		var c := Vector2(272 + p * 34, y + 146)
		Widgets.rounded(g, Rect2(c - Vector2(13, 7), Vector2(26, 14)), Paint.GREEN if p < lv else Color(1, 1, 1, 0.15), 7.0)
	var r := buy_rect(y)
	if cost < 0:
		Widgets.button(g, r, "MAX", Color(0.45, 0.45, 0.5), false, 44)
		return
	var afford := Save.coins >= cost
	Widgets.button(g, r, "", Color(0.98, 0.72, 0.2) if afford else Color(0.5, 0.48, 0.55), ready and afford)
	Widgets.coin(g, r.position + Vector2(52, r.size.y * 0.5), 20.0)
	Fx.label(g, str(cost), r.get_center() + Vector2(24, 0), 46, Paint.WHITE, true)


static func buy_rect(y: float) -> Rect2:
	return Rect2(700, y + 34, 230, 100)


static func hit(game: RecoilGame, at: Vector2) -> String:
	if PLAY.has_point(at):
		return "play"
	if not game.revived and REVIVE.has_point(at):
		return "revive"
	var i := 0
	for key in Save.UPGRADES:
		if buy_rect(ROW_Y + i * ROW_H).has_point(at):
			return key
		i += 1
	return ""
