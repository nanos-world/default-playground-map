-- Small props with their pivot at the bottom, a few picked for the hub's picnic table
HUB_FUN_PROPS = {
	"nanos-world::SM_Fruit_Watermelon_01_Half_01",
	"nanos-world::SM_Fruit_Pineapple_01",
	"nanos-world::SM_Bread_Pizza_01",
	"nanos-world::SM_Fruit_Banana_01",
	"nanos-world::SM_KidsBall",
	"nanos-world::SM_Toolbox_01",
	"nanos-world::SM_TVRemote",
	"nanos-world::SM_Bottle_01",
	"nanos-world::SM_CupC"
}

-- Pumpkins are kept for Halloween
if (Playground.theme == "halloween") then table.insert(HUB_FUN_PROPS, "nanos-world::SM_Fruit_Pumpkin_01") end

-- Places along the picnic table's length (its local X), one prop each
HUB_PICNIC_PLACES = { -80, -25, 30, 85 }

-- How far a jukebox carries (cm), where it differs from Sandbox's default: the hub's fills the whole hub
HUB_JUKEBOX_DISTANCE = {
	Hub_Jukebox = 10000,
	Museum_Jukebox = 3500
}

-- Sandbox's playlist a jukebox shuffles, where it is not the playground's: the museum only plays classical music
HUB_JUKEBOX_PLAYLIST = {
	Museum_Jukebox = "classical"
}
