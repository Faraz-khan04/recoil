class_name Paint
## Colours and small shape helpers shared by all the art.

const INK := Color(0.14, 0.11, 0.13)
const BRASS := Color(0.82, 0.63, 0.31)
const BRASS_DARK := Color(0.56, 0.4, 0.19)
const BRASS_LIGHT := Color(0.97, 0.83, 0.5)
const TEAL := Color(0.38, 0.78, 0.8)
const TEAL_DARK := Color(0.2, 0.5, 0.55)
const PINK := Color(1.0, 0.57, 0.74)
const PINK_DARK := Color(0.88, 0.38, 0.58)
const PINK_LIGHT := Color(1.0, 0.82, 0.9)
const GOLD := Color(1.0, 0.8, 0.22)
const GOLD_DARK := Color(0.82, 0.55, 0.1)
const GREEN := Color(0.4, 0.92, 0.5)
const RED_GLOW := Color(1.0, 0.18, 0.15)
const WHITE := Color(1, 1, 1)
const GLASS := Color(0.07, 0.05, 0.11, 0.55)       # dark see-through HUD panels

static var _body: Font


## Lilita One is the default (titles, numbers); Fredoka for small text.
static func setup_fonts() -> void:
	ThemeDB.fallback_font = load("res://fonts/LilitaOne-Regular.ttf")
	var v := FontVariation.new()
	v.base_font = load("res://fonts/Fredoka.ttf")
	v.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 600}
	_body = v


static func body() -> Font:
	return _body if _body else ThemeDB.fallback_font


static func ellipse(g: Batch, c: Vector2, rx: float, ry: float, rot: float, col: Color) -> void:
	g.draw_colored_polygon(ellipse_pts(c, rx, ry, rot), col)


static func ellipse_pts(c: Vector2, rx: float, ry: float, rot: float, n: int = 22) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return pts


## Filled circle with an ink outline.
static func blob(g: Batch, c: Vector2, r: float, col: Color, ink: float = 4.0) -> void:
	g.draw_circle(c, r + ink, INK)
	g.draw_circle(c, r, col)


static func star(c: Vector2, r: float, inner: float, points: int, rot: float = 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in points * 2:
		pts.append(c + Vector2.from_angle(rot - PI / 2 + PI * i / points) * (r if i % 2 == 0 else inner))
	return pts


## Teardrop pointing up (sweat drop).
static func drop(g: Batch, c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array([c + Vector2(0, -r * 2.0)])
	for i in 13:
		pts.append(c + Vector2.from_angle(-0.35 + (PI + 0.7) * i / 12.0) * r)
	g.draw_colored_polygon(pts, col)


## A little bullet shape pointing along `dir`.
static func bullet(g: Batch, c: Vector2, size: float, dir: Vector2, col: Color) -> void:
	var f := dir.normalized() * size
	var s := f.orthogonal() * 0.42
	g.draw_colored_polygon(PackedVector2Array([c - f * 0.8 - s, c + f * 0.2 - s, c + f * 0.8, c + f * 0.2 + s,
		c - f * 0.8 + s]), col)
	g.draw_line(c - f * 0.5 - s, c - f * 0.5 + s, BRASS_DARK, 3.0)
