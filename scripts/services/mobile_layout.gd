extends Node

## Phone layout: safe-area insets, larger touch targets, and a short on-screen hint.
## Desktop play is unchanged. ASHGRID_FORCE_PHONE=1 previews the phone layout.

const TOUCH_HINT = "Tap a tile to select or give an order. Drag to pan. Pinch to zoom."


func is_phone() -> bool:
	if OS.get_environment("ASHGRID_FORCE_PHONE") == "1":
		return true
	return OS.has_feature("mobile")


func _ready() -> void:
	if OS.get_environment("ASHGRID_SHOTS") != "1":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(2340, 1080))
	_failsafe()


func _failsafe() -> void:
	await get_tree().create_timer(120.0).timeout
	push_error("Ashgrid screenshot run timed out")
	get_tree().quit(1)


func save_screenshot(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		await RenderingServer.frame_post_draw
		image = get_viewport().get_texture().get_image()
	var directory := _shot_directory()
	DirAccess.make_dir_recursive_absolute(directory)
	var path := directory.path_join(file_name)
	var err := image.save_png(path)
	print("Ashgrid screenshot ", path, " ", image.get_width(), "x", image.get_height(), " err=", err)


func _shot_directory() -> String:
	var directory := OS.get_environment("ASHGRID_SHOT_DIR")
	if directory.is_empty():
		directory = "user://screenshots"
	if directory.begins_with("user://") or directory.begins_with("res://"):
		return ProjectSettings.globalize_path(directory)
	return directory


func insets() -> Vector4:
	# Screenshot runs pretend a landscape notch and a home indicator so the
	# captured frame shows the same padding a phone applies.
	if OS.get_environment("ASHGRID_SHOTS") == "1":
		return Vector4(54, 18, 28, 42)

	var safe := DisplayServer.get_display_safe_area()
	var window_size := DisplayServer.window_get_size()
	if window_size.x <= 0 or window_size.y <= 0:
		return Vector4.ZERO
	var viewport_size := get_viewport().get_visible_rect().size
	var scale_x := viewport_size.x / float(window_size.x)
	var scale_y := viewport_size.y / float(window_size.y)
	return Vector4(
		safe.position.x * scale_x,
		safe.position.y * scale_y,
		max(0.0, window_size.x - safe.position.x - safe.size.x) * scale_x,
		max(0.0, window_size.y - safe.position.y - safe.size.y) * scale_y
	)


func apply_safe_area(control: Control) -> void:
	if not is_phone():
		return
	var pad := insets()
	control.offset_left += pad.x
	control.offset_top += pad.y
	control.offset_right -= pad.z
	control.offset_bottom -= pad.w


func enlarge_text(node: Node) -> void:
	if node == null or node.has_meta(&"ashgrid_text"):
		return
	node.set_meta(&"ashgrid_text", true)
	if node is Control and (node is Label or node is Button or node is LineEdit or node is TextEdit):
		var control := node as Control
		var size := control.get_theme_font_size(&"font_size")
		if size <= 0:
			size = 16
		if size < 24:
			size = 24
		elif size < 40:
			size = int(size * 1.2)
		control.add_theme_font_size_override(&"font_size", size)
	for child in node.get_children():
		enlarge_text(child)


func enlarge_board(ui: Control) -> void:
	var buttons := ui.get_node_or_null("buttons")
	if buttons is Control:
		buttons.pivot_offset = Vector2(120, 120)
		buttons.scale = Vector2(1.65, 1.65)
	var resources := ui.get_node_or_null("resources")
	if resources is Control:
		resources.scale = Vector2(1.45, 1.45)
	var tile := ui.get_node_or_null("tile_highlight")
	if tile is Control:
		tile.scale = Vector2(1.35, 1.35)
	var radial := ui.get_node_or_null("radial/radial")
	if radial is Node2D:
		radial.scale = Vector2(1.12, 1.12)


func add_touch_hint(ui: Control) -> void:
	var hint := Label.new()
	hint.name = "TouchHint"
	hint.text = TOUCH_HINT
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.set_anchors_preset(Control.PRESET_CENTER_TOP)
	hint.offset_left = -460
	hint.offset_top = 12
	hint.offset_right = 460
	hint.offset_bottom = 56
	hint.add_theme_font_size_override(&"font_size", 26)
	hint.add_theme_color_override(&"font_color", Color(0.96, 0.91, 0.78))
	hint.add_theme_color_override(&"font_outline_color", Color(0, 0, 0))
	hint.add_theme_constant_override(&"outline_size", 6)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(hint)
	var tween := ui.create_tween()
	tween.tween_interval(6.0)
	tween.tween_property(hint, "modulate:a", 0.0, 0.8)
	tween.tween_callback(hint.queue_free)
