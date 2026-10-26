-- What each pad on the boulevard between the tool rows carries, the pads taking these sets in turn: x, y in the pad's axes, lift above its top (the pivot's height), and scale, yaw, roll and one_way (vehicles push it without feeling it) when set
PHYSICS_TOOL_PADS = {
	{
		{
			asset = "nanos-world::SM_Cube_VR_02",
			x = -80,
			y = -30,
			lift = 30,
			scale = 0.6,
			yaw = 15
		},
		{
			asset = "nanos-world::SM_Cube_VR_01",
			x = 30,
			y = 55,
			lift = 26,
			yaw = 40
		},
		{
			asset = "nanos-world::SM_Cube_VR_03",
			x = 95,
			y = -45,
			lift = 61,
			scale = 0.6
		},
		{
			asset = "nanos-world::SM_Ball_VR",
			x = -10,
			y = -50,
			lift = 26,
			scale = 0.35
		},
		{
			asset = "nanos-world::SM_Pyramid_VR",
			x = -95,
			y = 60,
			lift = 21,
			scale = 0.5,
			yaw = 30
		}
	},
	{
		{
			asset = "nanos-world::SM_WoodenTable",
			x = 0,
			y = 0,
			lift = 1
		},
		{
			asset = "nanos-world::SM_WoodenChair",
			x = -105,
			y = 0,
			lift = 1,
			yaw = -90
		},
		{
			asset = "nanos-world::SM_WoodenChair",
			x = 105,
			y = 0,
			lift = 1,
			yaw = 90
		},
		{
			asset = "nanos-world::SM_Toolbox_01",
			x = -20,
			y = 10,
			lift = 88,
			yaw = 20
		},
		{
			asset = "nanos-world::SM_Fruit_Watermelon_01",
			x = 35,
			y = -15,
			lift = 88
		}
	},
	{
		{
			asset = "nanos-world::SM_Crate_07",
			x = -80,
			y = -35,
			lift = 1
		},
		{
			asset = "nanos-world::SM_Crate_03",
			x = -80,
			y = -35,
			lift = 57,
			yaw = 20
		},
		{
			asset = "nanos-world::SM_Barrel_02",
			x = 35,
			y = -50,
			lift = 1
		},
		{
			asset = "nanos-world::SM_OilDrum",
			x = 95,
			y = 40,
			lift = 1
		},
		{
			asset = "nanos-world::SM_Bucket5Gallon",
			x = -10,
			y = 55,
			lift = 1
		}
	},
	{
		{
			asset = "nanos-world::SM_BarrelTub",
			x = -85,
			y = 0,
			lift = 1
		},
		{
			asset = "nanos-world::SM_Offroad_Tire",
			one_way = true,
			x = 35,
			y = -40,
			lift = 21,
			roll = 90
		},
		{
			asset = "nanos-world::SM_Cone",
			one_way = true,
			x = 105,
			y = 55,
			lift = 26,
			scale = 0.5
		},
		{
			asset = "nanos-world::SM_Basket_01",
			x = 15,
			y = 60,
			lift = 1
		},
		{
			asset = "nanos-world::SM_KidsBall",
			x = -85,
			y = 0,
			lift = 52
		}
	}
}

-- Loose props scattered on the plaza beside the physics gun, dealt from a shuffled deck so they rarely repeat: lift (its pivot's height when standing), and scale, roll and one_way when set
PHYSICS_SCATTER_PROPS = {
	{
		asset = "nanos-world::SM_Crate_07",
		lift = 1
	},
	{
		asset = "nanos-world::SM_Crate_03",
		lift = 1
	},
	{
		asset = "nanos-world::SM_Crate_04",
		lift = 1
	},
	{
		asset = "nanos-world::SM_Barrel_02",
		lift = 1
	},
	{
		asset = "nanos-world::SM_OilDrum",
		lift = 1
	},
	{
		asset = "nanos-world::SM_PlasticBarrel_01",
		lift = 1
	},
	{
		asset = "nanos-world::SM_BarrelTub",
		lift = 1
	},
	{
		asset = "nanos-world::SM_Bucket5Gallon",
		lift = 1
	},
	{
		asset = "nanos-world::SM_Basket_01",
		lift = 1
	},
	{
		asset = "nanos-world::SM_Toolbox_01",
		lift = 1
	},
	{
		asset = "nanos-world::SM_WoodenChair",
		lift = 1
	},
	{
		asset = "nanos-world::SM_RockingChair",
		lift = 3
	},
	{
		asset = "nanos-world::SM_Stool",
		lift = 1
	},
	{
		asset = "nanos-world::SM_CoffeeTable",
		lift = 1
	},
	{
		asset = "nanos-world::SM_Cube_VR_01",
		lift = 26
	},
	{
		asset = "nanos-world::SM_Cube_VR_02",
		lift = 30,
		scale = 0.6
	},
	{
		asset = "nanos-world::SM_Pyramid_VR",
		lift = 24,
		scale = 0.6
	},
	{
		asset = "nanos-world::SM_Ball_VR",
		lift = 26,
		scale = 0.35
	},
	{
		asset = "nanos-world::SM_Cone",
		one_way = true,
		lift = 26,
		scale = 0.5
	},
	{
		asset = "nanos-world::SM_Offroad_Tire",
		one_way = true,
		lift = 21,
		roll = 90
	},
	{
		asset = "nanos-world::SM_KidsBall",
		lift = 1
	},
	{
		asset = "nanos-world::SM_Fruit_Watermelon_01",
		lift = 1
	}
}

-- Pumpkins are kept for Halloween
if (Playground.theme == "halloween") then table.insert(PHYSICS_SCATTER_PROPS, { asset = "nanos-world::SM_Fruit_Pumpkin_01", lift = 1 }) end

-- One scattered prop per cell of this size, nudged inside it and turned at random, this part of the cells filled
PHYSICS_SCATTER_CELL = 120
PHYSICS_SCATTER_FILL = 0.75

-- A loose prop of the yard carried further than this is put back on the next refill
PHYSICS_LOOSE_REACH = 3000

-- The toys' orange, and the other tints they take in turn
PHYSICS_ORANGE = Color(0.9, 0.35, 0.05)

PHYSICS_TINTS = {
	Color(0.9, 0.35, 0.05),
	Color(0.95, 0.8, 0.1),
	Color(0.1, 0.55, 0.9),
	Color(0.85, 0.15, 0.45)
}

-- Elastics: bouncy balls on long, soft elastics under one beam, along its marker's Y: y, the elastic's length and its ball's tint
PHYSICS_ELASTICS = {
	{
		y = -130,
		length = 110,
		tint = Color(0.9, 0.35, 0.05)
	},
	{
		y = 0,
		length = 140,
		tint = Color(0.95, 0.8, 0.1)
	},
	{
		y = 130,
		length = 170,
		tint = Color(0.1, 0.55, 0.9)
	}
}

-- Fruit cannon: only the big ones that break apart (Sandbox's breakable props), they read from afar, knock the boxes over and burst
PHYSICS_CANNON_FRUITS = {
	"nanos-world::SM_Fruit_Watermelon_01",
	"nanos-world::SM_Fruit_Cantaloupe_01",
	"nanos-world::SM_Fruit_Squash_01"
}

-- Fireworks: each press sends up shells volley shells, interval ms apart, that burst fuse ms after they leave at speed; the button waits cooldown ms before the next volley
PHYSICS_FIREWORKS = {
	shells = 5,
	interval = 350,
	speed = 6000,
	fuse = 1500,
	cooldown = 3000
}

-- The bursts (ts-fireworks), one at random per shell
PHYSICS_FIREWORK_BURSTS = {
	"ts-fireworks::PS_TS_Fireworks_Burst_Chrys",
	"ts-fireworks::PS_TS_Fireworks_Burst_Circle",
	"ts-fireworks::PS_TS_Fireworks_Burst_Palm",
	"ts-fireworks::PS_TS_Fireworks_Burst_Shaped",
	"ts-fireworks::PS_TS_Fireworks_Burst_ShellsWithinShells"
}
