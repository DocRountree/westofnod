class_name BottlenoseDolphin
extends "res://scripts/creatures/cetacean.gd" # (by path: found whether or not the editor has seen the class yet)
## (Cetacean, its species "dolphin": see cetacean.gd.)


func _init(young_ := false) -> void:
	super(young_)
	species = "dolphin"
