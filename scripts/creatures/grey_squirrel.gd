class_name GreySquirrel
extends "res://scripts/creatures/fox_squirrel.gd" # (by path: found whether or not the editor has seen the class yet)
## An eastern grey squirrel (Sciurus carolinensis), on the fox squirrel's
## model and ways (FoxSquirrel: its bounding, sitting up, eating and
## caching nuts, climbing its tree head first down, the tail flicked, its
## drey and kits, the mating chase), a little larger here (size 0.33). Its
## coat (carnivore.gdshader's species 12): grizzled silver grey, washed
## brown along its back, over its head and down its legs; its belly,
## throat and the ring round each eye white; its ears grey, a white patch
## behind each; the tail grey, its long hairs banded black and tipped white,
## a silvery fringe round it. Its kits (GreySquirrel.new(true)): born in its
## drey, pink, naked, blind; furred as they grow.
##
## Its calls and steering are the fox squirrel's (see FoxSquirrel).


func _init(young_ := false) -> void:
	super(young_)
	size = 0.06 if young_ else 0.33
	_g_to = size


func _adult_size() -> float:
	return 0.33


func _coat_mat(part: int, pale := 0.0) -> ShaderMaterial:
	var m := super(part, pale)
	m.set_shader_parameter("species", 12)
	return m
