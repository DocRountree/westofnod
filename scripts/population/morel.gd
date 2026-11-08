class_name Morel
## Morels (Fungus: its models; data/population/props/morel.tres).


static func build(variant := 0) -> Mesh:
	return Fungus.levels("morel", variant)[0]


static func build_lods(variant := 0) -> Array[Mesh]:
	return Fungus.levels("morel", variant)[1]


static func variant_props(variant: int) -> Dictionary:
	return Fungus.variant_props("morel", variant)
