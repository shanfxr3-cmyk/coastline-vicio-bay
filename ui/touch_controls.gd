extends Control

## Touch-first HUD controls: multi-touch left virtual thumbstick, right swipe look,
## and 2026 glass-pill action/debug buttons.

const EventBusScript := preload("res://core/event_bus.gd")
const SettingsScript := preload("res://core/settings.gd")
const DebugScript := preload("res://core/debug.gd")

const STICK_RADIUS := 68.0
const STICK_KNOB_RADIUS := 28.0
const LOOK_SENSITIVITY := 0.0045

var _stick_touch_id: int = -1
var _look_touch_id: int = -1
var _stick_home: Vector2 = Vector2(140.0, -140.0)
var _stick_origin: Vector2 = Vector2.ZERO
var _stick_knob: Vector2 = Vector2.ZERO
var _move_vector: Vector2 = Vector2.ZERO

var _tod_button: Button = null
var _quality_button: Button = null
var _debug_button: Button = null
var _jump_button: Button = null
var _district_label: Label = null


func _eb() -> EventBusScript:
	return get_node_or_null("/root/EventBus") as EventBusScript


func _settings() -> SettingsScript:
	return get_node_or_null("/root/Settings") as SettingsScript


func _dbg() -> DebugScript:
	return get_node_or_null("/root/Debug") as DebugScript


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_hud()
	_update_stick_home()
	get_viewport().size_changed.connect(_update_stick_home)
	var eb := _eb()
	if eb != null:
		eb.quality_preset_changed.connect(_on_quality_changed)
		eb.time_of_day_changed.connect(_on_tod_changed)


func _update_stick_home() -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	_stick_home = Vector2(130.0, vp_size.y - 130.0)
	if _stick_touch_id == -1:
		_stick_origin = _stick_home
		_stick_knob = _stick_home
		queue_redraw()


func _build_hud() -> void:
	var top_bar := HBoxContainer.new()
	top_bar.anchor_left = 1.0
	top_bar.anchor_right = 1.0
	top_bar.anchor_top = 0.0
	top_bar.anchor_bottom = 0.0
	top_bar.offset_left = -430.0
	top_bar.offset_right = -16.0
	top_bar.offset_top = 14.0
	top_bar.offset_bottom = 58.0
	top_bar.alignment = BoxContainer.ALIGNMENT_END
	top_bar.add_theme_constant_override("separation", 8)
	add_child(top_bar)

	_tod_button = _make_pill_button("TOD: GOLDEN")
	_tod_button.pressed.connect(func() -> void:
		var eb := _eb()
		if eb != null:
			eb.touch_action_triggered.emit("cycle_tod")
	)
	top_bar.add_child(_tod_button)

	var st := _settings()
	_quality_button = _make_pill_button("QUAL: %s" % (st.get_preset_name() if st != null else "MEDIUM"))
	_quality_button.pressed.connect(func() -> void:
		var s := _settings()
		if s != null:
			s.cycle_preset()
	)
	top_bar.add_child(_quality_button)

	_debug_button = _make_pill_button("DBG")
	_debug_button.pressed.connect(func() -> void:
		var d := _dbg()
		if d != null:
			d.toggle_overlay()
	)
	top_bar.add_child(_debug_button)

	_district_label = Label.new()
	_district_label.anchor_left = 1.0
	_district_label.anchor_right = 1.0
	_district_label.offset_left = -360.0
	_district_label.offset_right = -18.0
	_district_label.offset_top = 64.0
	_district_label.offset_bottom = 92.0
	_district_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_district_label.text = "BAYFRONT PROMENADE  |  VICIO BAY"
	_district_label.add_theme_font_size_override("font_size", 12)
	_district_label.add_theme_color_override("font_color", Color(0.84, 0.93, 0.98, 0.85))
	add_child(_district_label)

	_jump_button = _make_pill_button("JUMP")
	_jump_button.anchor_left = 1.0
	_jump_button.anchor_right = 1.0
	_jump_button.anchor_top = 1.0
	_jump_button.anchor_bottom = 1.0
	_jump_button.offset_left = -156.0
	_jump_button.offset_right = -34.0
	_jump_button.offset_top = -132.0
	_jump_button.offset_bottom = -58.0
	_jump_button.pressed.connect(func() -> void:
		var eb := _eb()
		if eb != null:
			eb.touch_action_triggered.emit("jump")
	)
	add_child(_jump_button)


func _make_pill_button(title: String) -> Button:
	var btn := Button.new()
	btn.text = title
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(72.0, 40.0)
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0))

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.05, 0.11, 0.17, 0.72)
	normal.border_color = Color(0.0, 0.83, 1.0, 0.55)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(18)
	normal.content_margin_left = 12
	normal.content_margin_right = 12

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.0, 0.65, 0.82, 0.55)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", normal)
	btn.add_theme_stylebox_override("pressed", pressed)
	return btn


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		var vp_w: float = get_viewport_rect().size.x
		if touch.pressed:
			if _is_over_button(touch.position):
				return
			if touch.position.x < vp_w * 0.45 and _stick_touch_id == -1:
				_stick_touch_id = touch.index
				_stick_origin = touch.position
				_update_stick(touch.position)
			elif touch.position.x >= vp_w * 0.45 and _look_touch_id == -1:
				_look_touch_id = touch.index
		else:
			if touch.index == _stick_touch_id:
				_stick_touch_id = -1
				_stick_origin = _stick_home
				_stick_knob = _stick_home
				_move_vector = Vector2.ZERO
				var eb := _eb()
				if eb != null:
					eb.touch_move_updated.emit(_move_vector)
				queue_redraw()
			elif touch.index == _look_touch_id:
				_look_touch_id = -1

	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _stick_touch_id:
			_update_stick(drag.position)
		elif drag.index == _look_touch_id:
			var eb := _eb()
			if eb != null:
				eb.touch_look_updated.emit(drag.relative * LOOK_SENSITIVITY)


func _is_over_button(pos: Vector2) -> bool:
	for btn: Button in [_tod_button, _quality_button, _debug_button, _jump_button]:
		if btn != null and btn.visible and btn.get_global_rect().has_point(pos):
			return true
	return false


func _update_stick(touch_pos: Vector2) -> void:
	var delta: Vector2 = touch_pos - _stick_origin
	var dist: float = delta.length()
	if dist > STICK_RADIUS:
		delta = delta.normalized() * STICK_RADIUS
	_stick_knob = _stick_origin + delta
	_move_vector = delta / STICK_RADIUS
	var eb := _eb()
	if eb != null:
		eb.touch_move_updated.emit(_move_vector)
	queue_redraw()


func _process(_delta: float) -> void:
	var eb := _eb()
	if _stick_touch_id == -1:
		var key_vec := Vector2.ZERO
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			key_vec.x -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			key_vec.x += 1.0
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			key_vec.y -= 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			key_vec.y += 1.0
		if key_vec.length() > 1.0:
			key_vec = key_vec.normalized()
		if key_vec != _move_vector:
			_move_vector = key_vec
			_stick_knob = _stick_origin + _move_vector * (STICK_RADIUS * 0.7)
			if eb != null:
				eb.touch_move_updated.emit(_move_vector)
			queue_redraw()

	if Input.is_action_just_pressed("ui_accept"):
		if eb != null:
			eb.touch_action_triggered.emit("jump")


func _draw() -> void:
	draw_circle(_stick_origin, STICK_RADIUS, Color(0.05, 0.11, 0.18, 0.36))
	draw_arc(_stick_origin, STICK_RADIUS, 0.0, TAU, 48, Color(0.0, 0.83, 1.0, 0.48), 2.0, true)
	draw_circle(_stick_knob, STICK_KNOB_RADIUS, Color(0.88, 0.97, 1.0, 0.72))
	draw_arc(_stick_knob, STICK_KNOB_RADIUS, 0.0, TAU, 32, Color(1.0, 0.62, 0.24, 0.85), 2.0, true)


func _on_quality_changed(preset_name: String) -> void:
	if _quality_button != null:
		_quality_button.text = "QUAL: %s" % preset_name


func _on_tod_changed(phase_name: String, _elevation: float) -> void:
	if _tod_button != null:
		_tod_button.text = "TOD: %s" % phase_name.to_upper()
