extends Button
class_name PMenuButton

var image_back:NinePatchRect
@onready var image:NinePatchRect = NinePatchRect.new()
@onready var label:Label = Label.new()

@export var color:Color = Color.RED


func _ready():
	self_modulate.a = 0
	focus_mode = Control.FOCUS_NONE
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color",Color.WHITE)
	label.add_theme_color_override("font_outline_color",Color.BLACK)
	label.add_theme_font_override("font",preload("res://fonts/Nintendo-DS-BIOS.ttf"))
	label.add_theme_constant_override("outline_size",3)
	image.texture = preload("res://sprites/genericbutton.png")
	image.region_rect.size = Vector2(24,24)
	image.patch_margin_bottom = 7
	image.patch_margin_left = 7
	image.patch_margin_right = 7
	image.patch_margin_top = 7
	image_back = image.duplicate()
	image_back.texture = preload("res://sprites/genericbuttonback.png")
	image_back.position.y = 1
	add_child(image_back)
	add_child(image)
	add_child(label)

func _process(_delta):
	label.text = text
	label.size = size
	image.size = size
	image_back.size = size
	image.modulate = Color.WHITE.lerp(color,0.6) if button_pressed else Color.DARK_GRAY if disabled else color
	image.region_rect.position.x = image.region_rect.size.x*int(button_pressed)
	label.position.y = -int(!button_pressed)
