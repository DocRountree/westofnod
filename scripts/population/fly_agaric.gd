class_name FlyAgaric
## Fly agarics (Fungus: its models; data/population/props/fly_agaric.tres).


static func build(variant := 0) -> Mesh:
	return Fungus.levels("fly_agaric", variant)[0]


static func build_lods(variant := 0) -> Array[Mesh]:
	return Fungus.levels("fly_agaric", variant)[1]


static func variant_props(variant: int) -> Dictionary:
	return Fungus.variant_props("fly_agaric", variant)
