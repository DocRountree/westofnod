class_name LittleBrownCap
## Little brown caps (Fungus: its models; data/population/props/little_brown.tres).


static func build(variant := 0) -> Mesh:
	return Fungus.levels("little_brown", variant)[0]


static func build_lods(variant := 0) -> Array[Mesh]:
	return Fungus.levels("little_brown", variant)[1]


static func variant_props(variant: int) -> Dictionary:
	return Fungus.variant_props("little_brown", variant)
