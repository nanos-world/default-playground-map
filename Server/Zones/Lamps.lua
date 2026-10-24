-- Street lamps: SM_LightPole_A at every lamp spot with a light under its head and, when Sandbox runs, a switch on its pole to turn it on and off

local POLE = "nanos-world::SM_LightPole_A"

-- Squashed to 0.75 of its height (prelude.py LAMP_SCALE)
local POLE_SCALE = Vector(1, 1, 0.75)

-- SM_LightPole_A: pole at the origin, its arm along local +X, the lens (slot "Outside") 187 out with its underside at 813, 610 once squashed
local HEAD = Vector(187, 0, 603)

-- The switch on the pole's front (the arm's side, local +X), its back on the pole's surface
local SWITCH = Vector(10.5, 0, 120)

-- The lens's emissive (MI_Plastic_IlluMI_On's Illum_Intensity, 0.1 by default) while lit, and its color
local LENS_GLOW = 20
-- Warm sodium-like yellow, dim enough not to wash out the ground
local LAMP_COLOR = Color(1, 0.7, 0.3)
-- A wide cone down from the head, reaching far (cm), and culled past MAX_DISTANCE from the camera; no shadows, the most expensive part of a light
local LAMP_INTENSITY = 20
local LAMP_RADIUS, LAMP_CONE, LAMP_INNER_CONE = 2000, 80, 20
local MAX_DISTANCE = 7000
-- During Halloween a deep orange, the lens too
local HALLOWEEN_COLOR = Color(1, 0.32, 0.04)

-- The light and its lens go on and off together
local function SetLit(light, pole, is_on)
	if (light:IsValid()) then light:SetVisibility(is_on) end
	if (pole:IsValid()) then pole:SetMaterialScalarParameter("Illum_Intensity", is_on and LENS_GLOW or 0) end
end

Playground.Setup("Lamps", function()
	local color = Playground.theme == "halloween" and HALLOWEEN_COLOR or LAMP_COLOR
	for _, lamp in ipairs(LAMPS) do
		local light = Playground.Track(Light(Playground.At(lamp, HEAD.X, HEAD.Y, HEAD.Z), Rotator(-90, 0, 0), color, LightType.Spot, LAMP_INTENSITY, LAMP_RADIUS, LAMP_CONE, LAMP_INNER_CONE, MAX_DISTANCE, true, true))
		local pole = Playground.Track(StaticMesh(lamp.location, lamp.rotation, POLE, CollisionType.Normal))
		pole:SetScale(POLE_SCALE)
		pole:SetMaterialColorParameter("Illum_Color", color)
		SetLit(light, pole, true)

		-- The switch plate faces its local +Z with its long side along Y: rolled up and turned to face the arm's side (the lamp's +X), the toggle flipping up and down
		if (Playground.HasSandbox()) then
			local location, rotation = Playground.At(lamp, SWITCH.X, SWITCH.Y, SWITCH.Z), Rotator(0, lamp.rotation.Yaw + 90, -90)
			Playground.Button(location, rotation, "turn on", "turn off", function() SetLit(light, pole, true) end, function() SetLit(light, pole, false) end, true, "Switch", true, 1.4)
		end
	end
end)
