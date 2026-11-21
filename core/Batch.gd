class_name Batch
extends RefCounted
## Collects shapes as plain triangles and sends them to the screen as ONE
## draw call. (Each draw_circle / thick draw_line / polygon / outline used to
## be its own draw call: hundreds per frame, which made laptops and phones
## crawl.) Same method names as CanvasItem, so drawing code can take either a
## CanvasItem or a Batch. Edges get a thin fade for smooth, non-jagged lines.
## Text can't join the batch: draw_string sends what's collected first, so
## the stacking order stays right. Always end with flush().

const FEATHER := 1.4                 # px of edge fade on lines and circles

var _ci: CanvasItem
var _pts := PackedVector2Array()
var _cols := PackedColorArray()
var _idx := PackedInt32Array()
var _xf := Transform2D.IDENTITY
var alpha: float = 1.0               # everything drawn is faded by this


func _init(ci: CanvasItem) -> void:
	_ci = ci


func draw_set_transform(pos: Vector2, rot: float = 0.0, scale: Vector2 = Vector2.ONE) -> void:
	_xf = Transform2D(rot, scale, 0.0, pos)


func get_xf() -> Transform2D:
	return _xf


func set_xf(xf: Transform2D) -> void:
	_xf = xf


## Draw what follows scaled by s around point c (on top of the current transform).
func scale_around(c: Vector2, s: float) -> void:
	_xf = _xf * Transform2D(0.0, Vector2(s, s), 0.0, c) * Transform2D(0.0, -c)


## Raw triangles (Depth's side walls use this).
func add_tris(idx: PackedInt32Array, pts: PackedVector2Array, cols: PackedColorArray) -> void:
	var k := _pts.size()
	for p in pts:
		_pts.append(_xf * p)
	for c in cols:
		_cols.append(_a(c))
	for i in idx:
		_idx.append(k + i)


func draw_colored_polygon(poly: PackedVector2Array, col: Color, _a = null, _b = null) -> void:
	_fill(poly, PackedColorArray([col]))


func draw_polygon(poly: PackedVector2Array, cols: PackedColorArray, _a = null, _b = null) -> void:
	_fill(poly, cols)


func draw_circle(c: Vector2, r: float, col: Color, filled: bool = true, width: float = -1.0,
		_aa: bool = false) -> void:
	if not filled:
		draw_arc(c, r, 0.0, TAU, _segs(r), col, width)
		return
	var n := _segs(r)
	var k := _pts.size()
	_pts.append(_xf * c)
	col = _a(col)
	_cols.append(col)
	var clear := Color(col, 0.0)
	for i in n:
		var d := Vector2.from_angle(TAU * i / n)
		_pts.append(_xf * (c + d * r))
		_pts.append(_xf * (c + d * (r + FEATHER)))
		_cols.append_array([col, clear])
	for i in n:
		var a := k + 1 + i * 2
		var b := k + 1 + ((i + 1) % n) * 2
		_idx.append_array([k, a, b, a, a + 1, b + 1, a, b + 1, b])


func draw_line(a: Vector2, b: Vector2, col: Color, width: float = -1.0, _aa: bool = false) -> void:
	_quad(a, b, maxf(width, 1.0), col, col)


func draw_multiline(pairs: PackedVector2Array, col: Color, width: float = -1.0, _aa: bool = false) -> void:
	for i in range(0, pairs.size() - 1, 2):
		_quad(pairs[i], pairs[i + 1], maxf(width, 1.0), col, col)


func draw_multiline_colors(pairs: PackedVector2Array, cols: PackedColorArray, width: float = -1.0,
		_aa: bool = false) -> void:
	for i in range(0, pairs.size() - 1, 2):
		var c: Color = cols[mini(i / 2, cols.size() - 1)]
		_quad(pairs[i], pairs[i + 1], maxf(width, 1.0), c, c)


func draw_polyline(pts: PackedVector2Array, col: Color, width: float = -1.0, _aa: bool = false) -> void:
	var w := maxf(width, 1.0)
	for i in pts.size() - 1:
		_quad(pts[i], pts[i + 1], w, col, col)
	if w >= 3.5 and col.a > 0.99:    # round joints where thick lines turn sharply
		for i in range(1, pts.size() - 1):
			if absf((pts[i] - pts[i - 1]).angle_to(pts[i + 1] - pts[i])) > 0.45:
				draw_circle(pts[i], w * 0.5, col)


func draw_arc(c: Vector2, r: float, a0: float, a1: float, segs: int, col: Color,
		width: float = -1.0, _aa: bool = false) -> void:
	var pts := PackedVector2Array()
	for i in segs + 1:
		pts.append(c + Vector2.from_angle(lerpf(a0, a1, float(i) / segs)) * r)
	draw_polyline(pts, col, width)


func draw_rect(rect: Rect2, col: Color, filled: bool = true, width: float = -1.0, _aa: bool = false) -> void:
	var p := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end,
		Vector2(rect.position.x, rect.end.y)])
	if filled:
		_fill(p, PackedColorArray([col]))
	else:
		p.append(rect.position)
		draw_polyline(p, col, width)


## Text: send the shapes so far, then the text on top (same transform).
func draw_string(font: Font, pos: Vector2, text: String, align: int = 0, width: float = -1.0,
		size: int = 16, col: Color = Color.WHITE) -> void:
	flush()
	_ci.draw_set_transform_matrix(_xf)
	_ci.draw_string(font, pos, text, align, width, size, _a(col))
	_ci.draw_set_transform_matrix(Transform2D.IDENTITY)


func flush() -> void:
	if not _idx.is_empty():
		RenderingServer.canvas_item_add_triangle_array(_ci.get_canvas_item(), _idx, _pts, _cols)
	_pts.clear()
	_cols.clear()
	_idx.clear()


func _fill(poly: PackedVector2Array, cols: PackedColorArray) -> void:
	var n := poly.size()
	if n < 3:
		return
	var tri := Geometry2D.triangulate_polygon(poly)
	if tri.is_empty():                       # odd outline: fan (fine for near-convex)
		for i in range(1, n - 1):
			tri.append_array([0, i, i + 1])
	var k := _pts.size()
	for i in n:
		_pts.append(_xf * poly[i])
		_cols.append(_a(cols[i] if cols.size() == n else cols[0]))
	for i in tri:
		_idx.append(k + i)


## A thick line as a quad, plus a thin fading rim on both sides (smooth edge).
func _quad(a: Vector2, b: Vector2, w: float, ca: Color, cb: Color) -> void:
	var d := b - a
	if d.length_squared() < 0.0001:
		return
	var n := Vector2(-d.y, d.x).normalized()
	var h := n * (w * 0.5)
	var f := n * (w * 0.5 + FEATHER)
	var k := _pts.size()
	for p in [a + f, a + h, a - h, a - f, b + f, b + h, b - h, b - f]:
		_pts.append(_xf * p)
	ca = _a(ca)
	cb = _a(cb)
	var za := Color(ca, 0.0)
	var zb := Color(cb, 0.0)
	_cols.append_array([za, ca, ca, za, zb, cb, cb, zb])
	for s in 3:                              # outer fade, core, outer fade
		_idx.append_array([k + s, k + s + 1, k + s + 5, k + s, k + s + 5, k + s + 4])


func _a(c: Color) -> Color:
	return c if alpha >= 1.0 else Color(c, c.a * alpha)


static func _segs(r: float) -> int:
	return clampi(int(r * 0.5) + 8, 10, 40)
