-- Guns and tool guns laid on their side on a surface (Playground.LyingOnSide), by class: the centre of its mesh's bounds from its pivot and its half thickness lying down (the bounds' Y, which a 90 roll turns upright)
-- A class not listed lies like ToolGun (SK_ToolGun)
LYING_SHAPES = {
	-- SK_ToolGun
	ToolGun = {
		centre = Vector(12.85, 0, 6.33),
		half = 4.5
	},
	-- SK_GravityGun
	PhysicsGun = {
		centre = Vector(15.92, 0, 5.81),
		half = 8.04
	},
	PukeGun = {
		centre = Vector(9.12, 0, 2.48),
		half = 3.07
	},
	-- SK_AK47
	AK47 = {
		centre = Vector(17.89, 1.16, 0.52),
		half = 3.33
	},
	-- SK_Glock
	Glock = {
		centre = Vector(5.68, -0.07, 2.09),
		half = 1.67
	},
	-- SK_Moss500
	Moss500 = {
		centre = Vector(33.09, -0.03, 2.15),
		half = 1.98
	},
	-- SK_P90
	P90 = {
		centre = Vector(-3.86, 0, 5.36),
		half = 2.85
	}
}

-- Melees laid on their side (Playground.LyingMelee), by their NanosWorldWeapons name or mesh: they stand along their local Z from a pivot at the handle's end, so the centre of each along Z and along X (the crowbar's hook), and how far its side reaches below the pivot
LYING_MELEES = {
	Knife = {
		center = 8.5,
		x = 0,
		lift = 4
	},
	-- NanosWorldWeapons.Crowbar scales SM_Crowbar_01 by 1.5
	Crowbar = {
		center = 34.4,
		x = 4.9,
		lift = 2.6
	},
	BaseballBat = {
		center = 43,
		x = 0,
		lift = 3
	},
	["nanos-world::SM_Crowbar_01"] = {
		center = 23,
		x = 3,
		lift = 2
	},
	["nanos-world::SM_BaseballBat_01"] = {
		center = 43,
		x = 0,
		lift = 3
	}
}
