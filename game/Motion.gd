class_name Motion
## How each kind moves. `base` is its home spot; `p` is where it is now.


## pull = coin magnet radius; grab = radius at which ANY pickup slides to you.
static func move(th: Dictionary, player: Vector2, d: float, pull: float, grab: float) -> void:
	var k: int = th["k"]
	th["ph"] += d
	th["flash"] = maxf(0.0, th["flash"] - d * 5.0)
	var ph: float = th["ph"]
	var near: bool = player.distance_to(th["p"]) < 340.0
	th["alert"] = move_toward(th["alert"], 1.0 if near else 0.0, d * 4.0)
	match k:
		Kinds.PUFFER, Kinds.SHIELDED:           # lazy drift + bob
			th["p"] = th["base"] + Vector2(sin(ph * 0.8) * th["dx"], sin(ph * 2.2) * 12.0)
		Kinds.SWARMER:                          # neat triangle, slowly turning
			th["p"] = th["base"] + Vector2(sin(ph * 0.5) * 40.0, 0.0) \
				+ Vector2.from_angle(th["slot"] + ph * 0.7) * Kinds.FLOCK_R
		Kinds.URCHIN, Kinds.BOMBER:             # slow side-to-side
			th["p"] = th["base"] + Vector2(sin(ph * 0.6) * th["dx"] * 0.5, 0.0)
		Kinds.CHASER:                           # creeps toward you when close
			if player.distance_to(th["base"]) < 650.0:
				th["base"] += (player - th["base"]).normalized() * 150.0 * d
			th["p"] = th["base"]
		_:                                      # loot bobs, coins fly to the magnet
			var dist := player.distance_to(th["base"])
			var coin := k == Kinds.COIN or k == Kinds.MEGA
			if dist < grab or (coin and dist < pull):
				th["base"] = th["base"].move_toward(player, 1500.0 * d)
			th["p"] = th["base"] + Vector2(0.0, sin(ph * 3.0) * 8.0)
	th["p"].x = clampf(th["p"].x, 90.0, 990.0)
