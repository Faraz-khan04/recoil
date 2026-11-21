class_name Hud
## In-flight HUD on dark glass pills so it reads over anything passing under:
## hearts + shields (top left), coins (below), bullets (top right, 7 a row),
## height on a brass plate (middle) with progress to the next zone, power-up
## timers, combo, and the "you entered a new zone" banner.

const W := 1080.0


static func draw(g: Batch, game: RecoilGame) -> void:
	if game.state == RecoilGame.State.READY:
		return
	var w := game.world
	var pl := w.pl
	var hp_w := 3 * 66.0 + pl.shield * 58.0 + 30.0
	Widgets.pill(g, Rect2(70, 44, hp_w, 84))
	for i in 3:
		var lost := i >= pl.hearts
		Widgets.heart(g, Vector2(118 + i * 66, 84), 22.0, Color(0, 0, 0, 0.35) if lost else Color(0.95, 0.24, 0.34), not lost)
	for i in pl.shield:
		var c := Vector2(118 + 3 * 66 + i * 58, 84)
		g.draw_circle(c, 21.0, Color(0.55, 0.85, 1.0, 0.45))
		g.draw_arc(c, 21.0, 0.0, TAU, 20, Color(0.65, 0.9, 1.0), 4.0)
	Widgets.pill(g, Rect2(70, 142, 64.0 + 26.0 * str(w.coins).length() + 40.0, 66))
	Widgets.coin(g, Vector2(104, 175), 21.0)
	Widgets.text_left(g, str(w.coins), Vector2(136, 192), 44, Paint.WHITE, true)
	_ammo(g, w, pl)
	_height(g, game)
	var y := 222.0
	if w.golden_t > 0.0:
		_timer(g, "GOLDEN AMMO", w.golden_t / 6.0, y, Paint.GOLD)
		y += 66.0
	if w.magnet_t > 0.0:
		_timer(g, "SUPER MAGNET", w.magnet_t / 5.0, y, Color(0.95, 0.35, 0.42))
	if w.combo >= 2:
		var s := 46 + mini(w.combo, 10) * 3
		Widgets.rounded(g, Rect2(W * 0.5 - 140, 272, 280, 64), Color(0.1, 0.06, 0.02, 0.5), 32.0)
		Fx.label(g, "COMBO x%d" % w.combo, Vector2(W * 0.5, 304), s, Paint.GOLD, true)
	_banner(g, game)


static func _ammo(g: Batch, w: World, pl: Player) -> void:
	var n := maxi(pl.ammo, pl.clip)
	var per_row := 7
	var cols := mini(n, per_row)
	var rows := int(ceil(n / float(per_row)))
	var r := Rect2(W - 70 - (cols * 34 + 36), 44, cols * 34 + 36, 84 + (rows - 1) * 62)
	if rows == 1:
		Widgets.pill(g, r)
	else:
		Widgets.rounded(g, r, Paint.GLASS, 40.0)
	var gold := w.golden_t > 0.0
	for i in n:
		var c := Vector2(r.end.x - 36 - (i % per_row) * 34, 86 + (i / per_row) * 62)
		var full := i < pl.ammo or gold
		var col := (Paint.GOLD if gold else Paint.BRASS) if full else Color(1, 1, 1, 0.16)
		Paint.bullet(g, c, 28.0, Vector2.UP, col)
	if pl.ammo <= 1 and not gold and fmod(Time.get_ticks_msec() / 1000.0, 0.5) < 0.25:
		Widgets.rounded(g, r.grow(4.0), Color(1, 0.2, 0.2, 0.25), 44.0)


static func _height(g: Batch, game: RecoilGame) -> void:
	var plate := Rect2(W * 0.5 - 140, 38, 280, 104)
	Widgets.rounded(g, Rect2(plate.position + Vector2(0, 8), plate.size), Color(0, 0, 0, 0.3), 30.0)
	Widgets.rounded(g, plate.grow(4.0), Paint.INK, 34.0)
	Widgets.rounded(g, plate, Paint.BRASS_DARK, 30.0)
	Widgets.rounded(g, plate.grow(-6.0), Paint.BRASS, 26.0)
	Widgets.rounded(g, Rect2(plate.position + Vector2(14, 10), Vector2(plate.size.x - 28, 30)), Color(1, 1, 1, 0.2), 15.0)
	var txt := str(game.peak)
	var f := ThemeDB.fallback_font
	var tw := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 78).x
	Widgets.text_left(g, txt, Vector2(W * 0.5 - tw * 0.5 - 18, 118), 78, Paint.WHITE, true)
	Widgets.text_left(g, "m", Vector2(W * 0.5 + tw * 0.5 - 10, 118), 46, Paint.BRASS_LIGHT, true)
	var left := Zones.to_next(game.peak)
	if left < 0:
		return
	var bar := Rect2(W * 0.5 - 140, 158, 280, 14)
	Widgets.rounded(g, bar.grow(3.0), Paint.GLASS, 10.0)
	Widgets.rounded(g, Rect2(bar.position, Vector2(maxf(14.0, bar.size.x * Zones.progress(game.peak)), bar.size.y)), Paint.GOLD, 7.0)
	var nxt: String = Zones.LIST[Zones.index(game.peak) + 1]["name"]
	Fx.label(g, "%s in %d m" % [nxt, left], Vector2(W * 0.5, 200), 28, Paint.WHITE, true, Paint.body())


static func _timer(g: Batch, name: String, k: float, y: float, col: Color) -> void:
	Widgets.pill(g, Rect2(70, y, 330, 54))
	Widgets.text_left(g, name, Vector2(94, y + 36), 26, Paint.WHITE, true, Paint.body())
	var bar := Rect2(260, y + 20, 120, 14)
	Widgets.rounded(g, bar, Color(0, 0, 0, 0.4), 7.0)
	Widgets.rounded(g, Rect2(bar.position, Vector2(maxf(14.0, bar.size.x * k), bar.size.y)), col, 7.0)


## "ZONE 3 · STORM BELT" when you climb into a new zone.
static func _banner(g: Batch, game: RecoilGame) -> void:
	if game.banner_t <= 0.0:
		return
	var a := clampf(minf(game.banner_t, 2.6 - game.banner_t) * 3.0, 0.0, 1.0)
	var y := 760.0 - (1.0 - a) * 40.0
	g.alpha = a
	Widgets.rounded(g, Rect2(110, y - 110, W - 220, 200), Color(0.06, 0.04, 0.1, 0.7), 40.0)
	Widgets.rounded(g, Rect2(110, y - 110, W - 220, 8), Paint.GOLD, 4.0)
	Fx.label(g, "ZONE %d" % (game.zone_i + 1), Vector2(W * 0.5, y - 50), 34, Paint.GOLD, false, Paint.body())
	Fx.label(g, Zones.LIST[game.zone_i]["name"], Vector2(W * 0.5, y + 20), 84, Paint.WHITE, true)
	g.alpha = 1.0
