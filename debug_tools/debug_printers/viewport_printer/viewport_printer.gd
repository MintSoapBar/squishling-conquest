class_name ViewportPrinter
extends RichTextLabel


func _ready():
	print_("ViewportPrint loaded")


func print_(...vals: Array) -> void:
	for i in vals.size():
		text += str(vals[i])
	text += "\n"


func prints_(...vals: Array) -> void:
	for i in vals.size():
		text += str(vals[i]) + " "
	text += "\n"
