-- The native entities museum's colors: the Trigger and Text3D purple, each light's own color and the Trigger lamp's green
ENTITIES_PURPLE = Color(0.35, 0.1, 0.8)
ENTITIES_TRIGGER_COLOR = Color(0.1, 1, 0.2)

ENTITIES_LIGHT_COLORS = {
	LightPoint = Color(1, 0.6, 0.2),
	LightSpot = Color(0.3, 0.6, 1),
	LightRect = Color(0.6, 1, 0.5)
}

-- An exhibit carried further than this from its display is put back on the next refill
ENTITIES_EXHIBIT_REACH = 600

-- Physics objects on the Prop pad: x, y in the pad's axes and yaw
ENTITIES_PAD_PROPS = {
	{
		asset = "nanos-world::SM_PlasticBarrel_01",
		x = -70,
		y = -40,
		yaw = 0
	},
	{
		asset = "nanos-world::SM_Guitar",
		x = 60,
		y = -50,
		yaw = 20
	},
	{
		asset = "nanos-world::SM_Crate_Full_01",
		x = 0,
		y = 60,
		yaw = -15
	}
}

-- A prop on the Prop pad carried further than this is put back on the next refill
ENTITIES_PAD_REACH = 1500

-- The little shooting range by the pickables plaza: default-weapons' weapons lying on each table, like the range's armory
ENTITIES_RANGE_TABLES = {
	Entities_RangeTable1 = { "AP5", "P90", "M1911", "DesertEagle" },
	Entities_RangeTable2 = { "AR4", "Rem870", "AWP" }
}

-- A weapon moved further than this from its table goes back on it at the next refill
ENTITIES_RANGE_REACH = 100

-- Loose things to play with around each picnic table on the grass: x, y in the table's axes, scale, and z above the grass (on_table: on the table top instead, one_way: vehicles push it without feeling it)
ENTITIES_PICNIC_PROPS = {
	{
		asset = "nanos-world::SM_Ball_VR",
		x = 180,
		y = 140,
		scale = Vector(0.35, 0.35, 0.35),
		z = 25
	},
	{
		asset = "nanos-world::SM_Ball_VR",
		x = -220,
		y = -60,
		scale = Vector(0.35, 0.35, 0.35),
		z = 25
	},
	{
		asset = "nanos-world::SM_Cone",
		one_way = true,
		x = 260,
		y = -160,
		scale = Vector(0.5, 0.5, 0.5),
		z = 26
	},
	{
		asset = "nanos-world::SM_Cone",
		one_way = true,
		x = 300,
		y = -40,
		scale = Vector(0.5, 0.5, 0.5),
		z = 26
	},
	{
		asset = "nanos-world::SM_Cone",
		one_way = true,
		x = 340,
		y = 80,
		scale = Vector(0.5, 0.5, 0.5),
		z = 26
	},
	{
		asset = "nanos-world::SM_Crate_07",
		x = -200,
		y = 180,
		z = 2
	},
	{
		asset = "nanos-world::SM_Fruit_Watermelon_01",
		x = -40,
		y = 0,
		on_table = true
	},
	{
		asset = "nanos-world::SM_Fruit_Pineapple_01",
		x = 45,
		y = 10,
		on_table = true
	}
}

-- A picnic prop carried further than this is put back on the next refill
ENTITIES_PICNIC_REACH = 1500

-- Sounds the speaker plays, one per press in turn: short one-shots only (the car horns loop)
ENTITIES_SOUND_EFFECTS = {
	"nanos-world::A_Vehicle_Horn_Bike_01",
	"nanos-world::A_Robot_Beep_Whistle",
	"nanos-world::A_Fart",
	"nanos-world::A_Robot_Reaction",
	"nanos-world::A_Vehicle_Horn_Bike_02",
	"nanos-world::A_Robot_Sad"
}

-- The Dimension pad's other dimension, its color, and the cones floating around the pad that only it holds (x, y in the pad's axes, height)
ENTITIES_DIMENSION = 2
ENTITIES_DIMENSION_COLOR = Color(0.6, 0.1, 1)

ENTITIES_DIMENSION_CONES = {
	{
		x = 110,
		y = 110,
		z = 60
	},
	{
		x = -110,
		y = 110,
		z = 120
	},
	{
		x = -110,
		y = -110,
		z = 60
	},
	{
		x = 110,
		y = -110,
		z = 120
	}
}

-- Chickens pecking around inside their pen on the grass (580 inside), walking to a new random point every few seconds, at most this far from its middle
ENTITIES_CHICKENS = 5
ENTITIES_PEN_REACH = 220

-- How long the Particle Burst button waits after a press before it takes another (ms), so the explosion plays out first
ENTITIES_BURST_COOLDOWN = 3000
