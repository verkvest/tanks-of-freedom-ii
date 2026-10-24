extends Control

@onready var campaign_button = $"campaign_button"
@onready var skirmish_button = $"skirmish_button"
@onready var multiplayer_button = $"multiplayer_button"
@onready var load_button = $"load_button"
@onready var editor_button = $"editor_button"
@onready var settings_button = $"settings_button"
@onready var online_button = $"online_button"
@onready var quit_button = $"quit_button"
@onready var animations = $"animations"
@onready var gamepad_adapter = $"/root/GamepadAdapter"

@onready var switcher = $"/root/SceneSwitcher"
@onready var audio = $"/root/SimpleAudioLibrary"
@onready var mouse_layer = $"/root/MouseLayer"

var main_menu
var recent_button_used = null

func _ready():
	self.set_process_input(true)
	self.campaign_button.grab_focus()
	_apply_phone_menu()

	if OS.has_feature("demo"):
		self.online_button.set_disabled(true)


func _apply_phone_menu() -> void:
	if not MobileLayout.is_phone():
		return
	var buttons := [
		campaign_button, skirmish_button, multiplayer_button, load_button,
		online_button, editor_button, settings_button, quit_button,
	]
	var width := 300.0
	var height := 86.0
	var gap_x := 18.0
	var gap_y := 12.0
	var origin_x := -((width * 2.0 + gap_x) / 2.0)
	var origin_y := -8.0
	for i in buttons.size():
		var button = buttons[i]
		var column := i % 2
		var row := int(i / 2.0)
		button.offset_left = origin_x + column * (width + gap_x)
		button.offset_top = origin_y + row * (height + gap_y)
		button.offset_right = button.offset_left + width
		button.offset_bottom = button.offset_top + height
		var label := button.get_node_or_null("label") as Label
		if label:
			label.add_theme_font_size_override(&"font_size", 28)
	var background := $background as Control
	background.offset_left = origin_x - 18.0
	background.offset_top = origin_y - 18.0
	background.offset_right = origin_x + width * 2.0 + gap_x + 18.0
	background.offset_bottom = origin_y + 4.0 * height + 3.0 * gap_y + 18.0

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		self.quit_button.grab_focus()

	if OS.is_debug_build():
		if event.is_action_pressed("cheat_capture"):
			self.main_menu.ui.hide_menu()
			self.main_menu._start_intro()

func bind_menu(menu):
	self.main_menu = menu

func _on_skirmish_button_pressed():
	self.recent_button_used = self.skirmish_button
	self.audio.play("menu_click")
	self.main_menu.open_picker()

func _on_multiplayer_button_pressed():
	self.recent_button_used = self.multiplayer_button
	self.audio.play("menu_click")
	self.main_menu.open_multiplayer()


func _on_load_button_pressed():
	self.recent_button_used = self.load_button
	self.audio.play("menu_click")
	self.main_menu.open_saves()

func _on_editor_button_pressed():
	self.audio.play("menu_click")
	self.recent_button_used = self.editor_button
	self.audio.stop()
	self.gamepad_adapter.disable()
	self.switcher.map_editor()

func _on_settings_button_pressed():
	self.recent_button_used = self.settings_button
	self.audio.play("menu_click")
	self.main_menu.open_settings()

func _on_campaign_button_pressed():
	self.recent_button_used = self.campaign_button
	self.audio.play("menu_click")
	self.main_menu.open_campaign_selection()

func _on_online_button_pressed():
	self.recent_button_used = self.online_button
	self.audio.play("menu_click")
	self.main_menu.open_online()

func _on_quit_button_pressed():
	self.mouse_layer.destroy()
	self.get_tree().quit()

func show_panel():
	self.animations.play("show")
	self.set_process_input(true)
	await self.get_tree().create_timer(0.1).timeout

	if self.recent_button_used != null:
		self.recent_button_used.grab_focus()
	else:
		self.campaign_button.grab_focus()

func hide_panel():
	self.set_process_input(false)
	self.animations.play("hide")
