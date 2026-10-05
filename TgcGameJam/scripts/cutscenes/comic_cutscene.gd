extends CanvasLayer

signal finished

@export_category("Comic Pages")
@export var pages: Array[ComicPage] = []
@export var sequence: Array[Texture2D] = []

@export_category("Animation")
@export_range(0.05, 2.0, 0.05)
var panel_animation_time: float = 0.35

@export_range(0.0, 1.0, 0.01)
var panel_gap: float = 0.08

@onready var background: ColorRect = $Background
@onready var page_root: Control = $Page

var page_list: Array[ComicPage] = []
var page_index := 0
var panel_index := 0
var animating := false

var shown: Array[TextureRect] = []
var shown_sides: Array[ComicPanel.Side] = []


func _ready() -> void:
	background.color = Color.BLACK


func play() -> void:
	page_list = _build_pages()

	if page_list.is_empty():
		push_error("COMIC CUTSCENE HAS NO PANELS")
		visible = false
		return

	visible = true
	background.color = Color.BLACK
	page_index = 0
	panel_index = 0

	animating = true
	await _enter_panel()
	animating = false

	await finished

	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("advance_cutscene"):
		get_viewport().set_input_as_handled()
		if animating:
			return
		await _advance()


func _advance() -> void:
	animating = true

	if panel_index < page_list[page_index].panels.size() - 1:
		panel_index += 1
		await _enter_panel()

	elif page_index < page_list.size() - 1:
		await _leave_page()
		await get_tree().create_timer(panel_gap).timeout
		page_index += 1
		panel_index = 0
		await _enter_panel()

	else:
		await _leave_page()
		finished.emit()
		return

	animating = false


func _enter_panel() -> void:
	var data: ComicPanel = page_list[page_index].panels[panel_index]
	var area := _screen_size()

	var panel := TextureRect.new()
	panel.texture = data.texture
	panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size = data.rect.size * area

	var rest_position := data.rect.position * area
	panel.position = rest_position + _offscreen_offset(data.enter_from, rest_position, panel.size, area)

	page_root.add_child(panel)
	shown.append(panel)
	shown_sides.append(data.enter_from)

	await _move_panel(panel, rest_position, panel_animation_time).finished


func _leave_page() -> void:
	var area := _screen_size()
	var last_tween: Tween = null

	for i in shown.size():
		var panel := shown[i]
		var exit_side := _opposite(shown_sides[i])
		var target := panel.position + _offscreen_offset(exit_side, panel.position, panel.size, area)
		last_tween = _move_panel(panel, target, panel_animation_time)

	if last_tween:
		await last_tween.finished

	for panel in shown:
		panel.queue_free()
	shown.clear()
	shown_sides.clear()


func _offscreen_offset(side: ComicPanel.Side, rest_position: Vector2, panel_size: Vector2, area: Vector2) -> Vector2:
	match side:
		ComicPanel.Side.LEFT:
			return Vector2(-(rest_position.x + panel_size.x), 0.0)
		ComicPanel.Side.RIGHT:
			return Vector2(area.x - rest_position.x, 0.0)
		ComicPanel.Side.TOP:
			return Vector2(0.0, -(rest_position.y + panel_size.y))
		_:
			return Vector2(0.0, area.y - rest_position.y)


func _opposite(side: ComicPanel.Side) -> ComicPanel.Side:
	match side:
		ComicPanel.Side.LEFT:
			return ComicPanel.Side.RIGHT
		ComicPanel.Side.RIGHT:
			return ComicPanel.Side.LEFT
		ComicPanel.Side.TOP:
			return ComicPanel.Side.BOTTOM
		_:
			return ComicPanel.Side.TOP


func _move_panel(panel: Control, target_position: Vector2, duration: float) -> Tween:
	var tween: Tween = create_tween()

	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(panel, "position", target_position, duration)

	return tween


func _screen_size() -> Vector2:
	return get_viewport().get_visible_rect().size


func _build_pages() -> Array[ComicPage]:
	var built: Array[ComicPage] = []

	for page in pages:
		if page and not page.panels.is_empty():
			built.append(page)

	if not built.is_empty():
		return built

	for i in range(0, sequence.size(), 2):
		var page := ComicPage.new()
		var has_pair := i + 1 < sequence.size()

		var first := ComicPanel.new()
		first.texture = sequence[i]
		first.rect = Rect2(0.05, 0.04, 0.9, 0.44) if has_pair else Rect2(0.05, 0.05, 0.9, 0.9)
		first.enter_from = ComicPanel.Side.LEFT
		page.panels.append(first)

		if has_pair:
			var second := ComicPanel.new()
			second.texture = sequence[i + 1]
			second.rect = Rect2(0.05, 0.52, 0.9, 0.44)
			second.enter_from = ComicPanel.Side.RIGHT
			page.panels.append(second)

		built.append(page)

	return built
