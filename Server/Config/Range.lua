-- Every weapon in default-weapons (grenades are at the explosives range), one table per family laid out from one end to the other: the first four tables stand in front of the short range, the rest in front of the long range
RANGE_ARMORY = {
	{
		table = "Range_Armory_Pistols",
		weapons = { "Glock", "M1911", "Makarov", "DesertEagle", "ColtPython" }
	},
	{
		table = "Range_Armory_SMGs",
		weapons = { "AP5", "UMP45", "P90", "SMG11", "Sten" }
	},
	{
		table = "Range_Armory_Shotguns",
		weapons = { "Moss500", "Rem870", "Ithaca37", "SPAS12" }
	},
	{
		table = "Range_Armory_Melee",
		weapons = { "Knife", "Crowbar", "BaseballBat" },
		is_melee = true
	},
	{
		table = "Range_Armory_Assault",
		weapons = { "AK47", "AR4", "GE36", "AK5C" }
	},
	{
		table = "Range_Armory_Carbines",
		weapons = { "AK74U", "SA80", "ASVal", "StG44" }
	},
	{
		table = "Range_Armory_Battle",
		weapons = { "GE3", "BAR", "Lewis" }
	},
	{
		table = "Range_Armory_Blasters",
		weapons = { "BlasterRifle", "BlasterPistol" }
	},
	{
		table = "Range_Armory_Snipers",
		weapons = { "AWP", "M1Garand" }
	}
}

-- A weapon moved further than this from its table goes back on it at the next refill
RANGE_WEAPON_REACH = 100

-- Grenades on the throwing wall
RANGE_GRENADES = 4

-- The explosives on the barrel spots, only things that would really blow up: metal drums, propane tanks and gas canisters; one blown up comes back this long (ms) after it is gone
RANGE_BARREL_ASSETS = {
	"nanos-world::SM_Barrel_01",
	"nanos-world::SM_PropaneTank_01",
	"nanos-world::SM_TallGasCanister_01",
	"nanos-world::SM_PropaneTank_02",
	"nanos-world::SM_Canister"
}

RANGE_BARREL_RESPAWN = 15000

-- Things to shoot on the construction props (range.py "Range_Shoot_*" markers), plain props of meshes Sandbox breaks by itself (its BREAKABLE_PROPS)
RANGE_SHOOTABLES = {
	"nanos-world::SM_Fruit_Watermelon_01",
	"nanos-world::SM_Fruit_Cantaloupe_01"
}

-- Things that break on the ground of the explosives range (range.py "Range_Grenade_Breakable*" markers), also from Sandbox's BREAKABLE_PROPS
RANGE_GROUND_BREAKABLES = {
	"nanos-world::SM_ConcreteBag_Stack_01",
	"nanos-world::SM_Trash_01",
	"nanos-world::SM_Fruit_Watermelon_01",
	"nanos-world::SM_Fruit_Squash_01"
}

-- A shootable or ground breakable comes back this long (ms) after it is gone
RANGE_SHOOTABLE_RESPAWN = 6000

-- Outside a game a shot target stands up again this long (ms) after it falls, one of its column at random
RANGE_IDLE_RISE = 3000

-- The shooting game: a round of time seconds after a countdown, with from up_count[1] to up_count[2] targets up at once in every lane as it goes on
RANGE_GAME = {
	time = 60,
	countdown = 3,
	up_count = { 1, 3 }
}

-- Per range (range.py RANGES' names): its title on the board, and how long targets stay up and the pause before the next ones (s, at the start and at the end of a round)
RANGE_GAMES = {
	Short = {
		title = "SHORT RANGE",
		up = { 1.8, 0.8 },
		gap = { 0.6, 0.25 }
	},
	Long = {
		title = "LONG RANGE",
		up = { 2.8, 1.4 },
		gap = { 0.8, 0.35 }
	}
}

-- The referee's whistle from the board (once when a round starts, twice when it ends, gap ms apart); the targets clang by themselves (Sandbox Target)
RANGE_WHISTLE = {
	asset = "nanos-world::A_Referee_Whistle",
	falloff = 2500,
	volume = 0.35,
	gap = 450
}
