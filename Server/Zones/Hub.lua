-- Hub: the time and weather panel standing by the trees west of the plaza (labels are drawn by the client, Client/Texts.lua), a jukebox by the fountain and props on a picnic table

-- Push buttons point up their local +Z: a 90 roll turns that out of the panel's face (its local +Y)
local BUTTON_ROLL = 90

-- Small props with their pivot at the bottom, for the picnic table
local FUN_PROPS = {
	"nanos-world::SM_Fruit_Watermelon_01_Half_01",
	"nanos-world::SM_Fruit_Pineapple_01",
	"nanos-world::SM_Bread_Pizza_01",
	"nanos-world::SM_Fruit_Banana_01",
	"nanos-world::SM_KidsBall",
	"nanos-world::SM_Toolbox_01",
	"nanos-world::SM_TVRemote",
	"nanos-world::SM_Bottle_01",
	"nanos-world::SM_CupC",
}
-- Pumpkins are kept for Halloween
if (Playground.theme == "halloween") then table.insert(FUN_PROPS, "nanos-world::SM_Fruit_Pumpkin_01") end

-- How far a jukebox carries (cm), where it differs from Sandbox's default: the hub's fills the whole hub
local JUKEBOX_DISTANCE = { Hub_Jukebox = 10000, Museum_Jukebox = 3500 }

-- Sandbox's playlist a jukebox shuffles, where it is not the playground's: the museum only plays classical music
local JUKEBOX_PLAYLIST = { Museum_Jukebox = "classical" }

-- Sandbox owns the sky (and keeps it in sync for late joiners), so go through its console commands
local function ApplySky(button)
	if (button.weather) then
		Console.RunCommand(string.format("weather %d 5", button.weather))
	else
		Console.RunCommand(string.format("time %d %d", button.hours, button.minutes))
	end
end

-- The fountain's water on its spout (hub.py "Hub_FountainWater" marker): the particle here, the running water loop on each client (Client/Index.lua)
local function SpawnFountain()
	local spot = Playground.Spot("Hub_FountainWater")
	if (spot) then
		Playground.Track(Particle(spot.location, Rotator(), "nanos-world::P_Fountain", false, true))
	end
end

Playground.Setup("Hub", function()
	SpawnFountain()

	-- Sandbox's Jukebox on every "*_Jukebox" spot around the map, playing from the start (its song, volume and on/off are in its context menu)
	if (Playground.HasSandbox() and Jukebox) then
		for name, spot in pairs(SPOTS) do
			if (name:sub(-8) == "_Jukebox") then
				local location, rotation = Playground.Top(spot, 1), Rotator(0, Playground.FrontYaw(spot), 0)
				local distance = JUKEBOX_DISTANCE[name]
				Playground.Slot(function() return Jukebox(location, rotation, JUKEBOX_PLAYLIST[name] or "playground", nil, nil, distance) end)
			end
		end
	end

	local picnic = Playground.Spot("Hub_PicnicTable")
	if (picnic) then
		local yaw = Playground.FrontYaw(picnic)

		-- A few of the FUN_PROPS scattered along the table, a new pick every time
		for i, x in ipairs({ -80, -25, 30, 85 }) do
			local asset = FUN_PROPS[math.random(#FUN_PROPS)]
			local location = Playground.At(picnic, x, math.random(-15, 15), picnic.top + 2)
			-- The fruit and the pizza break like Sandbox's by themselves
			Playground.Slot(function()
				return Prop(location, Rotator(0, yaw + math.random(-40, 40), 0), asset, CollisionType.Normal, true, GrabMode.Enabled)
			end, 400)
		end
	end

	local panel = Playground.Spot("Hub_SkyPanel")
	if (not panel or not Playground.HasSandbox()) then return end

	local rotation = Rotator(0, panel.rotation.Yaw, BUTTON_ROLL)

	for _, button in ipairs(SKY_BUTTONS) do
		Playground.Button(Playground.SkyButtonLocation(panel, button), rotation, "press", "press", function()
			ApplySky(button)
		end, nil, false, "PushButton")
	end
end)
