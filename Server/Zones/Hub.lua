-- Hub: the time and weather panel standing by the trees west of the plaza (labels are drawn by the client, Client/Texts.lua), the jukeboxes around the map, the fountain and props on a picnic table

-- Push buttons point up their local +Z: a 90 roll turns that out of the panel's face (its local +Y)
local BUTTON_ROLL = 90

-- A prop knocked further than this from the picnic table is put back on the next refill
local PICNIC_REACH = 400

-- Sandbox owns the sky (and keeps it in sync for late joiners), so go through its console commands
local function ApplySky(button)
	if (button.weather) then
		Console.RunCommand(string.format("weather %d 5", button.weather))
	else
		Console.RunCommand(string.format("time %d %d", button.hours, button.minutes))
	end
end

-- The fountain's water on its spout (hub.py "Hub_FountainWater" marker): the particle here, the running water loop on each client (Client/Effects.lua)
local function SpawnFountain()
	local spot = Playground.Spot("Hub_FountainWater")
	if (not spot) then return end

	Playground.Track(Particle(spot.location, Rotator(), "nanos-world::P_Fountain", false, true))
end

-- Sandbox's Jukebox on every "*_Jukebox" spot around the map, playing from the start (its song, volume and on/off are in its context menu)
local function SpawnJukeboxes()
	for name, spot in pairs(SPOTS) do
		if (name:sub(-8) == "_Jukebox") then
			local location, rotation = Playground.Top(spot, 1), Rotator(0, Playground.FrontYaw(spot), 0)
			local playlist, distance = HUB_JUKEBOX_PLAYLIST[name] or "playground", HUB_JUKEBOX_DISTANCE[name]

			Playground.Slot(function() return Jukebox(location, rotation, playlist, nil, nil, distance) end)
		end
	end
end

-- A few of the HUB_FUN_PROPS scattered along the table, a new pick every time (the fruit and the pizza break like Sandbox's by themselves)
local function SpawnPicnic(picnic)
	local yaw = Playground.FrontYaw(picnic)

	for _, x in ipairs(HUB_PICNIC_PLACES) do
		local asset = HUB_FUN_PROPS[math.random(#HUB_FUN_PROPS)]
		local location = Playground.At(picnic, x, math.random(-15, 15), picnic.top + 2)

		Playground.Slot(function()
			return Prop(location, Rotator(0, yaw + math.random(-40, 40), 0), asset, CollisionType.Normal, true, GrabMode.Enabled)
		end, PICNIC_REACH)
	end
end

local function SpawnSkyPanel(panel)
	local rotation = Rotator(0, panel.rotation.Yaw, BUTTON_ROLL)

	for _, button in ipairs(HUB_SKY_BUTTONS) do
		Playground.Button(Playground.SkyButtonLocation(panel, button), rotation, "press", "press", function() ApplySky(button) end, nil, { kind = "PushButton", switchable = false })
	end
end

Playground.Setup("Hub", function()
	SpawnFountain()

	local picnic = Playground.Spot("Hub_PicnicTable")
	if (picnic) then SpawnPicnic(picnic) end

	if (not Playground.HasSandbox()) then return end

	SpawnJukeboxes()

	local panel = Playground.Spot("Hub_SkyPanel")
	if (panel) then SpawnSkyPanel(panel) end
end)
