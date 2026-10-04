extends CanvasLayer

signal finished

@export var sequence: Array[Texture2D] = []

@onready var background: ColorRect = $Background

@onready var page_content: Control = $Page/PageContent

@onready var top_holder: Control = $Page/PageContent/TopHolder
@onready var bottom_holder: Control = $Page/PageContent/BottomHolder

@onready var top_panel: TextureRect = $Page/PageContent/TopHolder/TopPanel
@onready var bottom_panel: TextureRect = $Page/PageContent/BottomHolder/BottomPanel


var current_index: int = 0
var animating: bool = false

var top_rest_position: Vector2 = Vector2.ZERO
var bottom_rest_position: Vector2 = Vector2.ZERO


const PANEL_ANIMATION_TIME: float = 0.35
const PANEL_GAP: float = 0.08


func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	_setup_holders()

	top_rest_position = top_holder.position
	bottom_rest_position = bottom_holder.position

	background.color = Color.BLACK
	background.modulate.a = 1.0

	print("SEQUENCE SIZE: ", sequence.size())
	print("TOP HOLDER REST: ", top_rest_position)
	print("BOTTOM HOLDER REST: ", bottom_rest_position)
	print("PAGE CONTENT SIZE: ", page_content.get_size())


func _setup_holders() -> void:
	var page_width_value: float = page_content.get_size().x
	var page_height_value: float = page_content.get_size().y

	var horizontal_margin: float = 10.0
	var vertical_margin: float = 10.0
	var middle_gap: float = 10.0

	var panel_width: float = page_width_value - (horizontal_margin * 2.0)

	var half_height: float = page_height_value / 2.0

	var panel_height: float = (
		half_height
		- vertical_margin
		- (middle_gap / 2.0)
	)

	# --------------------------------
	# TOP HOLDER
	# --------------------------------

	top_holder.position = Vector2(
		horizontal_margin,
		vertical_margin
	)

	top_holder.size = Vector2(
		panel_width,
		panel_height
	)

	# --------------------------------
	# BOTTOM HOLDER
	# --------------------------------

	bottom_holder.position = Vector2(
		horizontal_margin,
		half_height + (middle_gap / 2.0)
	)

	bottom_holder.size = Vector2(
		panel_width,
		panel_height
	)


func play() -> void:
	visible = true

	animating = true
	current_index = 0

	background.color = Color.BLACK
	background.modulate.a = 1.0

	if sequence.is_empty():
		push_error("COMIC CUTSCENE HAS NO PANELS")

		finished.emit()

		visible = false
		animating = false

		return

	# Recalculate the holders every time the cutscene starts.
	_setup_holders()

	top_rest_position = top_holder.position
	bottom_rest_position = bottom_holder.position

	_reset_visuals()

	await get_tree().process_frame

	await _enter_top_panel()

	animating = false

	await finished

	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if animating:
		return

	if event.is_action_pressed("advance_cutscene"):
		await _advance()


func _advance() -> void:
	if animating:
		return

	animating = true

	# Last panel.
	if current_index >= sequence.size() - 1:
		await _finish_cutscene()
		return

	current_index += 1

	# Odd index = bottom panel.
	if current_index % 2 == 1:
		await _enter_bottom_panel()

	# Even index = new page.
	else:
		await _change_page()

	animating = false


func _enter_top_panel() -> void:
	if current_index >= sequence.size():
		return

	top_panel.texture = sequence[current_index]
	bottom_panel.texture = null

	# Start above-left of the page.
	top_holder.position = top_rest_position + Vector2(
		-page_width(),
		-page_height()
	)

	await _move_panel(
		top_holder,
		top_rest_position,
		PANEL_ANIMATION_TIME
	)


func _enter_bottom_panel() -> void:
	if current_index >= sequence.size():
		return

	bottom_panel.texture = sequence[current_index]

	# Start below-right of the page.
	bottom_holder.position = bottom_rest_position + Vector2(
		page_width(),
		page_height()
	)

	await _move_panel(
		bottom_holder,
		bottom_rest_position,
		PANEL_ANIMATION_TIME
	)


func _change_page() -> void:
	# --------------------------------
	# OLD PAGE LEAVES
	# --------------------------------

	var top_tween: Tween = _move_panel(
		top_holder,
		top_rest_position + Vector2(
			page_width(),
			-page_height()
		),
		PANEL_ANIMATION_TIME
	)

	var bottom_tween: Tween = _move_panel(
		bottom_holder,
		bottom_rest_position + Vector2(
			-page_width(),
			page_height()
		),
		PANEL_ANIMATION_TIME
	)

	await top_tween.finished
	await bottom_tween.finished

	# Tiny pause between pages.
	await get_tree().create_timer(PANEL_GAP).timeout

	# --------------------------------
	# CLEAR OLD PAGE
	# --------------------------------

	top_panel.texture = null
	bottom_panel.texture = null

	# --------------------------------
	# LOAD NEW TOP PANEL
	# --------------------------------

	top_panel.texture = sequence[current_index]

	# Start new top panel from top-right.
	top_holder.position = top_rest_position + Vector2(
		page_width(),
		-page_height()
	)

	await get_tree().process_frame

	# Move new top panel into place.
	await _move_panel(
		top_holder,
		top_rest_position,
		PANEL_ANIMATION_TIME
	)


func _finish_cutscene() -> void:
	# --------------------------------
	# BOTH PANELS LEAVE
	# --------------------------------

	var top_tween: Tween = _move_panel(
		top_holder,
		top_rest_position + Vector2(
			page_width(),
			-page_height()
		),
		PANEL_ANIMATION_TIME
	)

	var bottom_tween: Tween = _move_panel(
		bottom_holder,
		bottom_rest_position + Vector2(
			-page_width(),
			page_height()
		),
		PANEL_ANIMATION_TIME
	)

	await top_tween.finished
	await bottom_tween.finished

	# Keep the screen black until
	# CutsceneManager fades back to gameplay.
	background.color = Color.BLACK
	background.modulate.a = 1.0

	finished.emit()


func _move_panel(
	panel: Control,
	target_position: Vector2,
	duration: float
) -> Tween:

	var tween: Tween = create_tween()

	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		panel,
		"position",
		target_position,
		duration
	)

	return tween


func _reset_visuals() -> void:
	top_panel.texture = null
	bottom_panel.texture = null

	top_holder.position = top_rest_position
	bottom_holder.position = bottom_rest_position


func page_width() -> float:
	return page_content.get_size().x


func page_height() -> float:
	return page_content.get_size().y
