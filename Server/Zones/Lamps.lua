-- Street lamps: SM_LightPole_A at every lamp spot with a light under its head and, when Sandbox runs, a switch on its pole to turn it on and off
-- A car driving fast at a pole knocks it over and its lamp goes out, both back a while later

local POLE = "nanos-world::SM_LightPole_A"

-- Squashed to 0.75 of its height (prelude.py LAMP_SCALE)
local POLE_SCALE = Vector(1, 1, 0.75)

-- SM_LightPole_A: pole at the origin, its arm along local +X, the lens (slot "Outside") 187 out with its underside at 813, 610 once squashed
local HEAD = Vector(187, 0, 603)

-- The switch on the pole's front (the arm's side, local +X), its back on the pole's surface
local SWITCH = Vector(10.5, 0, 120)
local SWITCH_SCALE = 1.4

-- When a broken lamp toggles (ms after the hit), off first and off last
local FLICKER = { 60, 140, 220, 380, 500 }

-- How long the sparks of a broken lamp last (s)
local SPARKS_LIFE = 1.5

-- The light and its lens go on and off together
local function SetLit(light, pole, is_on)
	if (light:IsValid()) then light:SetVisibility(is_on) end
	if (pole:IsValid()) then pole:SetMaterialScalarParameter("Illum_Intensity", is_on and STREET_LAMP_LENS_GLOW or 0) end
end

local function SpawnLamp(lamp, color)
	local config = STREET_LAMP_LIGHT
	local head = Playground.At(lamp, HEAD.X, HEAD.Y, HEAD.Z)
	local light = Playground.Track(Light(head, Rotator(-90, 0, 0), color, LightType.Spot, config.intensity, config.radius, config.cone, config.inner_cone, config.draw_distance, true, true))

	-- A Prop without gravity does not simulate, so it stands as still as a StaticMesh until a car knocks it over
	local pole = Playground.Track(Prop(lamp.location, lamp.rotation, POLE, CollisionType.Normal, false, GrabMode.Disabled, CCDMode.Enabled))
	pole:SetScale(POLE_SCALE)
	pole:SetMaterialColorParameter("Illum_Color", color)
	pole:SetValue("Unbreakable", true)

	local is_switched_on, is_broken, switch = true, false, nil

	SetLit(light, pole, true)

	-- The switch on the pole, only with Sandbox; gone while the pole is down, back as it was left
	local function SpawnSwitch()
		if (not Playground.HasSandbox()) then return end

		-- The switch plate faces its local +Z with its long side along Y: rolled up and turned to face the arm's side (the lamp's +X), the toggle flipping up and down
		local location, rotation = Playground.At(lamp, SWITCH.X, SWITCH.Y, SWITCH.Z), Rotator(0, lamp.rotation.Yaw + 90, -90)

		local function Switch(is_on)
			is_switched_on = is_on
			SetLit(light, pole, is_on)
		end

		switch = Playground.Button(location, rotation, "turn on", "turn off", function() Switch(true) end, function() Switch(false) end, { kind = "Switch", is_on = is_switched_on, scale = SWITCH_SCALE })
	end

	-- Lets the pole go before the car reaches it, simulated by whoever drives the car so it hits a body of its own physics; laggy drivers may still hit it stiff
	local function Break(vehicle)
		is_broken = true

		pole:SetNetworkAuthority(vehicle:GetNetworkAuthority())
		pole:SetGravityEnabled(true)

		if (switch and switch:IsValid()) then switch:Destroy() end

		local sparks = Particle(head, Rotator(), "nanos-world::P_SparksFlair", true, true)
		sparks:AttachTo(pole, AttachmentRule.KeepWorld)

		-- In case it loops, it would never end by itself
		sparks:SetLifeSpan(SPARKS_LIFE)

		-- More sparks where the pole snaps off its foot, left there as it falls
		Particle(lamp.location, Rotator(), "nanos-world::P_SparksFlair", true, true):SetLifeSpan(SPARKS_LIFE)

		Playground.PlaySound(head, "nanos-world::A_Sparks")

		for i, delay in ipairs(FLICKER) do
			Timer.SetTimeout(function()
				if (is_broken) then SetLit(light, pole, i % 2 == 0) end
			end, delay)
		end

		Timer.SetTimeout(function()
			if (not pole:IsValid()) then return end

			pole:SetGravityEnabled(false)
			pole:SetNetworkAuthority(nil)
			pole:SetLocation(lamp.location)
			pole:SetRotation(lamp.rotation)

			is_broken = false
			SetLit(light, pole, is_switched_on)
			SpawnSwitch()
		end, STREET_LAMP_BREAK.respawn)
	end

	-- Only a car already heading at the pole fast enough when it gets near breaks it, a slower one hits it like a wall
	local trigger = Playground.Track(Trigger(lamp.location + Vector(0, 0, 100), Rotator(), STREET_LAMP_BREAK.reach, TriggerType.Sphere, false, Color.RED, { "VehicleWheeled" }))

	trigger:Subscribe("BeginOverlap", function(_, vehicle)
		if (is_broken) then return end

		local velocity, towards = vehicle:GetVelocity(), lamp.location - vehicle:GetLocation()
		velocity.Z, towards.Z = 0, 0

		-- A released pole falls over by itself, so only one the car's line passes close to (miss: how far its middle goes by the pole) is let go
		local heading = velocity:GetSafeNormal()
		local ahead = towards:Dot(heading)
		local miss = (towards - heading * ahead):Size()

		if (ahead > 0 and velocity:Size() >= STREET_LAMP_BREAK.speed and miss <= STREET_LAMP_BREAK.width) then Break(vehicle) end
	end)

	SpawnSwitch()
end

Playground.Setup("Lamps", function()
	local color = Playground.theme == "halloween" and HALLOWEEN_LAMP_COLOR or STREET_LAMP_COLOR

	for _, lamp in ipairs(LAMPS or {}) do
		SpawnLamp(lamp, color)
	end
end)
