-- The museum's pictures (Client/Images/Museum)
MUSEUM_IMAGE_DIR = "package://" .. Package.GetName() .. "/Client/Images/Museum/"

-- The gallery's pictures in gilded frames on its "Museum_Gallery<n>" spots, in museum.py GALLERY's order (picture n matches plaque n); style is a PhotoFrame.styles name
MUSEUM_GALLERY = {
	{
		image = "mona_lisa.jpg",
		style = "gold_tall"
	},
	{
		image = "scream.jpg",
		style = "gold_tall"
	},
	{
		image = "starry.jpg",
		style = "gold_wide"
	},
	{
		image = "pearl.jpg",
		style = "gold_tall"
	},
	{
		image = "napoleon.jpg",
		style = "gold_wide"
	},
	{
		image = "persistence.jpg",
		style = "gold_wide"
	}
}

-- Every gallery picture's scale, and how high its middle hangs above its spot
MUSEUM_GALLERY_SCALE = 0.75
MUSEUM_GALLERY_MIDDLE = 77

-- The gilded paintings on "Museum_Painting_<name>" spots (scaled by the spot): their frame and picture
MUSEUM_PAINTINGS = {
	Creator = {
		style = "gold_square",
		image = "creator.jpg"
	}
}

-- Each gilded frame style's height at scale 1 (playground_props.py: PaintingTall 202, PaintingWide 180 tall)
MUSEUM_FRAME_HEIGHTS = {
	gold_square = 202,
	gold_wide = 180,
	gold_tall = 202
}

-- The Mingebag Hall of Shame's heap, laid out by hand as static meshes (no physics: a dropped heap kept blowing itself across the hall): offset from the spot (x into the hall, y across it, z up)
MUSEUM_SHAME_PILE = {
	{
		mesh = "nanos-world::SM_Tire_01",
		offset = Vector(-40, 30, 31),
		rotation = Rotator(90, 0, 0)
	},
	{
		mesh = "nanos-world::SM_MicrowaveOven",
		offset = Vector(-40, 30, 62),
		rotation = Rotator(0, 30, 0)
	},
	{
		mesh = "nanos-world::SM_Bucket5Gallon",
		offset = Vector(-35, 25, 151),
		rotation = Rotator(0, 10, 180)
	},
	{
		mesh = "nanos-world::SM_CartonBox_01",
		offset = Vector(45, -40, 0),
		rotation = Rotator(0, 20, 0)
	},
	{
		mesh = "nanos-world::SM_Crate_01",
		offset = Vector(40, -35, 65),
		rotation = Rotator(0, -15, 0)
	},
	{
		mesh = "nanos-world::SM_Fruit_Watermelon_01",
		offset = Vector(100, -15, 14),
		rotation = Rotator(0, 40, 0)
	},
	{
		mesh = "nanos-world::SM_TV",
		offset = Vector(30, 60, 0),
		rotation = Rotator(0, 60, -12)
	},
	{
		mesh = "nanos-world::SM_TrashCan_01",
		offset = Vector(-20, -75, 33),
		rotation = Rotator(90, 0, 0)
	},
	{
		mesh = "nanos-world::SM_WoodenChair",
		offset = Vector(-80, -10, 30),
		rotation = Rotator(0, 120, 90)
	},
	{
		mesh = "nanos-world::SM_RockingChair",
		offset = Vector(90, 40, 0),
		rotation = Rotator(0, -140, 0)
	}
}

-- Garry's Mod bouncy balls filling their glass cabinet, in the classic four colors
MUSEUM_BALL_COLORS = {
	Color(0.8, 0.02, 0.02),
	Color(0.02, 0.05, 0.8),
	Color(0.85, 0.7, 0.02),
	Color(0.03, 0.75, 0.05)
}

-- The bouncy balls' heap, built once ball by ball: each one dropped at the lowest of tries random places, where it rests on the floor or the balls under it, until drops have been tried (the ones that would stick out of the top are left out)
-- radius: the range of their sizes; room: the space inside the glass from the spot (playground_props.py VitrineCabinet: 98 x 62 inside, 150 tall, the spot's X across its depth and Y along its width); seed: the same heap every time
MUSEUM_BALL_HEAP = {
	radius = { 16, 21 },
	room = {
		x = 30,
		y = 48,
		z = 148
	},
	tries = 300,
	drops = 80,
	seed = 99
}

-- A ball carried further than this from the cabinet is put back on the next refill
MUSEUM_BALL_REACH = 600

-- The plastic barrel on the missing texture stand, painted with it too
MUSEUM_MISSING_REACH = 1500
