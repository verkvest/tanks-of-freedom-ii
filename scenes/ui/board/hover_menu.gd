extends Control

const FADE_OUT_TIME = 3.0

@onready var animations = $"animations"

var board = null
var fade_out_timer = 0.0
var hover_stack = 0
var phone_commands := false

var hovered_button = null

func _ready():
	pass # Replace with function body.

func enable_phone_commands() -> void:
	phone_commands = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layout_phone_buttons()
	for path in [
		"turn_button/mouse_click",
		"build_button/button_anchor/mouse_click",
		"stats_button/button_anchor/mouse_click",
		"skills_button/button_anchor/mouse_click",
	]:
		var area := get_node_or_null(path) as Area2D
		if area:
			area.input_pickable = false
	visible = true
	modulate = Color(1, 1, 1, 1)


func _layout_phone_buttons() -> void:
	var step := 120.0
	_place_command($"build_button", -step)
	_place_command($"stats_button", -step * 2.0)
	_place_command($"skills_button", -step * 3.0)


func _place_command(button: Control, left: float) -> void:
	button.offset_left = left
	button.offset_top = 0.0
	button.offset_right = left + 120.0
	button.offset_bottom = 120.0


func consume_screen_press(screen_pos: Vector2) -> bool:
	if not phone_commands or not visible:
		return false
	if board == null or not board._can_current_player_perform_actions():
		return false
	var best := ""
	var best_distance := INF
	for button_name in ["turn", "build", "stats", "skills"]:
		if not _command_visible(button_name):
			continue
		var anchor := _command_anchor(button_name)
		if anchor == null:
			continue
		var radius := 58.0 * anchor.get_global_transform().get_scale().x
		var distance := screen_pos.distance_to(anchor.global_position)
		if distance <= radius and distance < best_distance:
			best = button_name
			best_distance = distance
	if best == "":
		return false
	hovered_button = best
	_perform_action()
	return true


func _command_visible(button_name: String) -> bool:
	if button_name == "turn":
		return true
	var button := get_node_or_null(button_name + "_button") as CanvasItem
	return button != null and button.visible


func _command_anchor(button_name: String) -> Node2D:
	if button_name == "turn":
		return $"turn_button"
	return get_node_or_null(button_name + "_button/button_anchor") as Node2D


func _input(event):
	if not get_window().has_focus():
		return

	if self.board == null:
		return

	if phone_commands:
		return

	if event is InputEventMouseMotion:
		self.fade_out_timer = 0.0
		if self._should_pop_up():
			self._fade_in()

	if self.is_visible():
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			self.call_deferred("_perform_action")

func _should_pop_up():
	return not self.is_visible() and self.board._can_current_player_perform_actions() and not self.board.ui.radial.is_visible() and not self.board.ui.is_popup_open()

func _should_clear():
	return self.is_visible() and (not self.board._can_current_player_perform_actions() or self.board.ui.radial.is_visible() or self.board.ui.is_popup_open())


func _physics_process(delta):
	if self.board == null:
		return

	if self.board.selected_tile != null:
		if self.board.selected_tile.building.is_present():
			$"build_button".show()
		else:
			$"build_button".hide()

		if self.board.selected_tile.unit.is_present():
			$"stats_button".show()
			if self.board.selected_tile.unit.tile.has_active_ability():
				$"skills_button".show()
			else:
				$"skills_button".hide()
		else:
			$"stats_button".hide()
			$"skills_button".hide()
	else:
		$"build_button".hide()
		$"stats_button".hide()
		$"skills_button".hide()


	if phone_commands:
		if self._should_clear():
			self.visible = false
		elif self.board._can_current_player_perform_actions():
			self.visible = true
			self.modulate.a = 1.0
		return

	if self.is_visible() and self.fade_out_timer > self.FADE_OUT_TIME:
		self._fade_out()

	if self._should_clear():
		self._fade_out()

	self.fade_out_timer += delta


func _fade_in():
	self.hover_stack = 0
	self.animations.play("show")

func _fade_out():
	self.hover_stack = 0
	self.animations.play("hide")

func _on_mouse_click_mouse_entered(button):
	if self.board == null:
		return

	self.hover_stack += 1
	self.hovered_button = button

	if button == "turn":
		$"turn_button/white".show()
	elif button == "build":
		$"build_button/button_anchor/white".show()
	elif button == "stats":
		$"stats_button/button_anchor/white".show()
	elif button == "skills":
		$"skills_button/button_anchor/white".show()

		
func _on_mouse_click_mouse_exited(button):
	if self.board == null:
		return

	self.hover_stack -= 1
	if self.hovered_button == button:
		self.hovered_button = null

	if button == "turn":
		$"turn_button/white".hide()
	elif button == "build":
		$"build_button/button_anchor/white".hide()
	elif button == "stats":
		$"stats_button/button_anchor/white".hide()
	elif button == "skills":
		$"skills_button/button_anchor/white".hide()

func _perform_action():
	if self.board == null:
		return

	if self.hovered_button == "turn":
		self.board.check_end_turn()
		self._fade_out()
	elif self.hovered_button == "build":
		self.board._show_contextual_select_radial(true)
	elif self.hovered_button == "stats":
		self.board._open_context_panel_for_active_tile()
	elif self.hovered_button == "skills":
		self.board._show_contextual_select_radial(true)

	self.hovered_button = null
