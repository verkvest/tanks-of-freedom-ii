extends Control

@onready var audio = $"/root/SimpleAudioLibrary"

@onready var animations = $"animations"
@onready var back_button = $"widgets/back_button"

var main_menu

func bind_menu(menu):
	self.main_menu = menu

func _ready():
	self.set_process_input(false)
	_load_license_text()


func _load_license_text() -> void:
	var label := $widgets/credits as Label
	var file := FileAccess.open("res://THIRD_PARTY_LICENSES.md", FileAccess.READ)
	if file:
		label.text = file.get_as_text()
		file.close()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	var scroll := ScrollContainer.new()
	scroll.name = "license_scroll"
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 24.0
	scroll.offset_top = 24.0
	scroll.offset_right = -24.0
	scroll.offset_bottom = -96.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	$widgets.add_child(scroll)
	$widgets.move_child(scroll, 0)
	label.reparent(scroll)
	label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	label.position = Vector2.ZERO
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size = Vector2(720, 0)
	if MobileLayout.is_phone():
		back_button.offset_left = 430.0
		back_button.offset_top = 508.0
		back_button.offset_right = 760.0
		back_button.offset_bottom = 584.0
	
func _input(event):
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed('editor_menu'):
		self._on_back_button_pressed()

func _on_back_button_pressed():
	self.audio.play("menu_back")
	self.main_menu.close_credits()

func show_panel():
	self.animations.play("show")
	self.set_process_input(true)
	await self.get_tree().create_timer(0.1).timeout
	self.back_button.grab_focus()

func hide_panel():
	self.animations.play("hide")
	self.set_process_input(false)
