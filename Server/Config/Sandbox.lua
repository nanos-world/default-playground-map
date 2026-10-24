-- The physics guns' and puke guns' tables show two each, side by side and pointing opposite ways, this far from its middle each (the puke gun is bulkier)
SANDBOX_PAIRED_APART = {
	PhysicsGun = 15,
	PukeGun = 20
}

-- Each puke gun of the pair starts on its own option (PukeGun.options ids)
SANDBOX_PUKE_OPTIONS = { "watermelons", "balloons" }

-- The spawner stall's tables ("Sandbox_Item_<tool>"), in this order: the class of the sandbox entity each tool spawns, shown on its table
SANDBOX_SPAWNER_ITEMS = {
	{
		tool = "BalloonGun",
		class = "Balloon"
	},
	{
		tool = "ThrusterGun",
		class = "Thruster"
	},
	{
		tool = "WheelGun",
		class = "Wheel"
	},
	{
		tool = "TrailGun",
		class = "Trail"
	},
	{
		tool = "LightGun",
		class = "Lamp"
	},
	{
		tool = "ButtonGun",
		class = "LogicButton"
	}
}

-- What the stalls show takes these tints in turn
SANDBOX_SHOW_TINTS = {
	Color(0.9, 0.35, 0.05),
	Color(0.95, 0.8, 0.1),
	Color(0.1, 0.55, 0.9),
	Color(0.85, 0.15, 0.45),
	Color(0.2, 0.75, 0.3)
}

-- The tool stall's big painted props, one picked per table in turn (scale, and lift: its pivot above the table), and the giant resized melon
SANDBOX_SHOW_BIG = {
	{
		asset = "nanos-world::SM_Cube",
		scale = 0.55,
		lift = 28
	}
}

SANDBOX_SHOW_GIANT = {
	asset = "nanos-world::SM_Fruit_Watermelon_01",
	scale = 3,
	lift = 2
}

-- The trailer the house's button plays on its TV, and how long (ms) before it turns itself off
SANDBOX_TRAILER_URL = "https://www.youtube.com/watch?v=fVYYIg88VzU"
SANDBOX_TRAILER_DURATION = 120000

-- The house's lamp by the door: warm and dim, its bulb glowing with its color times glow (Sandbox's rope lights use 100)
SANDBOX_HOUSE_LAMP = {
	color = Color(1, 0.75, 0.45),
	intensity = 3,
	glow = 8
}

-- The Sandbox Sign by the house door
SANDBOX_SIGN_TEXT = "welcome to\nsandbox house"

-- The picture in the house's PhotoFrame (Client/Images/Sandbox)
SANDBOX_PHOTO_FRAME_IMAGE = "package://" .. Package.GetName() .. "/Client/Images/Sandbox/photo_frame.jpg"
