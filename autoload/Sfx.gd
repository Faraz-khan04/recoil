extends Node
## Tiny sound kit made in code (no audio files). Sfx.play("shoot", pitch).
## Sounds: shoot, hit, kill, boom, slurp, click, win, lose, coin, shield, bonk.

const RATE := 22050
const VOICES := 12

var _sounds := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_sounds["shoot"] = _make(0.07, func(t, k): return _sq(t * lerpf(900.0, 300.0, k)) * 0.35 + _noise() * 0.25 * (1.0 - k))
	_sounds["hit"] = _make(0.05, func(t, k): return _noise() * 0.5 * (1.0 - k))
	_sounds["kill"] = _make(0.14, func(t, k): return sin(TAU * t * lerpf(520.0, 180.0, k)) * 0.6 + _noise() * 0.2 * (1.0 - k))
	_sounds["boom"] = _make(0.45, func(t, k): return _noise() * pow(1.0 - k, 2.0) * 0.9 + sin(TAU * t * lerpf(90.0, 40.0, k)) * 0.5 * (1.0 - k))
	_sounds["slurp"] = _make(0.12, func(t, k): return sin(TAU * t * lerpf(250.0, 1100.0, k * k)) * 0.45)
	_sounds["click"] = _make(0.04, func(t, k): return _sq(t * 1800.0) * 0.25 * (1.0 - k))
	_sounds["coin"] = _make(0.16, func(t, k): return sin(TAU * t * (1320.0 if k > 0.3 else 990.0)) * 0.35)
	_sounds["win"] = _make(0.5, func(t, k): return sin(TAU * t * [523.0, 659.0, 784.0, 1046.0][mini(int(k * 4.0), 3)]) * 0.35)
	_sounds["shield"] = _make(0.22, func(t, k): return sin(TAU * t * lerpf(1400.0, 700.0, k)) * 0.35 + sin(TAU * t * 2100.0) * 0.15 * (1.0 - k))
	_sounds["bonk"] = _make(0.1, func(t, k): return sin(TAU * t * lerpf(380.0, 620.0, k)) * 0.5)
	_sounds["lose"] = _make(0.5, func(t, k): return _sq(t * lerpf(300.0, 80.0, k)) * 0.3 * (1.0 - k))


func play(name: String, pitch: float = 1.0, vol_db: float = 0.0) -> void:
	if not _sounds.has(name):
		return
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = _sounds[name]
	p.pitch_scale = pitch * randf_range(0.94, 1.06)
	p.volume_db = vol_db
	p.play()


## Builds a sound from f(time, progress 0..1) -> sample, with a fade-out tail.
func _make(secs: float, f: Callable) -> AudioStreamWAV:
	var n := int(secs * RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var k := float(i) / n
		var s: float = f.call(float(i) / RATE, k)
		s *= minf(1.0, (1.0 - k) * 12.0)
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = data
	return w


static func _sq(phase: float) -> float:
	return 1.0 if fmod(phase, 1.0) < 0.5 else -1.0


static func _noise() -> float:
	return randf() * 2.0 - 1.0
