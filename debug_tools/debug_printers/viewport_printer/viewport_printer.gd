class_name ViewportPrinter
extends RichTextLabel


var enabled: bool = false


func _ready():
	print_("ViewportPrint loaded")
	
	if not enabled:
		visible = false


func print_(...vals: Array) -> void:
	for i in vals.size():
		text += str(vals[i])
	text += "\n"


func prints_(...vals: Array) -> void:
	for i in vals.size():
		text += str(vals[i]) + " "
	text += "\n"
