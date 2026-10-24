-- Per seat stand-in (prelude.py SEAT_PROPS name): the Sandbox Chair style it becomes with Sandbox, and the mesh of the plain Prop without it
SEAT_TYPES = {
	Chair = {
		style = "PlaygroundChair",
		mesh = "nanos-world::SM_PG_Chair"
	},
	Bench = {
		style = "PlaygroundBench",
		mesh = "nanos-world::SM_PG_Bench"
	},
	WoodenChair = {
		style = "Wooden",
		mesh = "nanos-world::SM_WoodenChair"
	}
}

-- A seat shoved further than this from its spot (the physics gun) is put back on the next refill
SEAT_REACH = 300
