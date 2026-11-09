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
			return Prop(location, Rotator(0, yaw + math.random(-40, 40), 0), asset, CollisionType.Auto, true, GrabMode.Enabled)
		end, PICNIC_REACH)
	end
end

local function SpawnSkyPanel(panel)
	local rotation = Rotator(0, panel.rotation.Yaw, BUTTON_ROLL)

	for _, button in ipairs(HUB_SKY_BUTTONS) do
		Playground.Button(Playground.SkyButtonLocation(panel, button), rotation, "press", "press", function() ApplySky(button) end, nil, { kind = "PushButton", switchable = false })
	end
end

-- Every connected player must be present, including the one pressing; players loading or without a character block the reset
local function SpawnReset(spot)
	if (not spot.radius or spot.radius <= 0) then return end

	local location = Playground.Top(spot, 0)
	local button

	button = Playground.PushButton(spot, "reset playground", function(player, causer)
		if (not player or not player:IsValid()) then return end

		local character = player:GetControlledCharacter()

		-- Only a nearby player's interaction can reset, never a projectile, wire or remote press from elsewhere
		if (not character or not character:IsValid() or causer ~= character or character:GetLocation():Distance(location) > 200) then return end

		local missing = 0

		for _, other in pairs(Player.GetPairs()) do
			local pawn = other:GetControlledCharacter()
			local offset = pawn and pawn:IsValid() and pawn:GetLocation() - spot.location or nil

			if (not offset or offset.X * offset.X + offset.Y * offset.Y > spot.radius * spot.radius or math.abs(offset.Z - 90) > 200) then
				missing = missing + 1
			end
		end

		if (missing > 0) then
			Events.CallRemote("Playground:Error", player, Reliability.Reliable, string.format("All players must be within %g m of this button (%d missing).", spot.radius / 100, missing))
			return
		end

		-- Latches the button down and prevents further presses until the map reloads
		button:SetSwitchable(nil, true)
		button:SetValue("Active", true, true)
		button:SetPressable(false)
		button.Press = function() return false end

		Sandbox.Reset(player)
	end, 0)
end

Playground.Setup("Hub", function()
	SpawnFountain()

	local picnic = Playground.Spot("Hub_PicnicTable")
	if (picnic) then SpawnPicnic(picnic) end

	if (not Playground.HasSandbox()) then return end

	SpawnJukeboxes()

	local reset = Playground.Spot("Hub_Reset")
	if (reset) then SpawnReset(reset) end

	local panel = Playground.Spot("Hub_SkyPanel")
	if (panel) then SpawnSkyPanel(panel) end
end)
