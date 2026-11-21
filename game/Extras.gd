class_name Extras
## Pickups and the drone buddy, kept apart from World so it stays short.


static func collect(w: World, th: Dictionary) -> void:
	th["hp"] = 0
	match th["k"]:
		Kinds.COIN, Kinds.MEGA:
			w.coins += Kinds.COINS[th["k"]]
			w.fx.text("+%d" % Kinds.COINS[th["k"]], th["p"], Color(1, 0.8, 0.2), 46)
			Sfx.play("coin", 1.0 if th["k"] == Kinds.COIN else 0.7)
		Kinds.AMMO:
			w.pl.ammo = maxi(w.pl.ammo, w.pl.clip)
			w.fx.text("FULL AMMO!", th["p"], Color(0.4, 0.95, 0.5), 52)
			Sfx.play("slurp")
		Kinds.MAGNET:
			w.magnet_t = 5.0
			w.fx.text("SUPER MAGNET!", th["p"], Color(1, 0.4, 0.4), 52)
			Sfx.play("slurp", 1.3)
		Kinds.GOLDEN:
			w.golden_t = 6.0
			w.fx.text("GOLDEN AMMO!", th["p"], Color(1, 0.85, 0.2), 52)
			Sfx.play("win")


## Drone buddy: circles you and pops the nearest puffer or urchin now and then.
static func drone(w: World, d: float) -> void:
	var lv := Save.level("drone")
	if lv <= 0:
		return
	w.drone_ang += d * 2.4
	w.drone_t -= d
	if w.drone_t > 0.0:
		return
	var at := drone_pos(w)
	for th in w.things:
		if th["hp"] > 0 and not Kinds.loot(th["k"]) and th["p"].distance_to(at) < 520.0:
			var dir: Vector2 = (th["p"] - at).normalized()
			w.shots.append({"p": at, "v": dir * World.SHOT_SPEED, "life": 0.4, "bounce": 0, "gold": false, "drone": true})
			Sfx.play("shoot", 2.0, -10.0)
			w.drone_t = [0.0, 2.2, 1.6, 1.1][mini(lv, 3)]
			return


static func drone_pos(w: World) -> Vector2:
	return w.pl.p + Vector2.from_angle(w.drone_ang) * 105.0
