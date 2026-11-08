class_name ChickenOfTheWoods
## Chicken of the woods (Fungus: its models; data/population/props/chicken_of_the_woods.tres).


static func build(variant := 0) -> Mesh:
	return Fungus.levels("chicken_of_the_woods", variant)[0]


static func build_lods(variant := 0) -> Array[Mesh]:
	return Fungus.levels("chicken_of_the_woods", variant)[1]


static func variant_props(variant: int) -> Dictionary:
	return Fungus.variant_props("chicken_of_the_woods", variant)
