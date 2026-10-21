-- Street lamps: a light under every lamp head in the level and, when Sandbox runs, a switch on its pole to turn it on and off

-- SM_PH_Lamp: pole at the origin, head 60 along local +Y with its underside at 405
local HEAD = Vector(0, 60, 398)
-- The switch on the pole's front (the head's side, local +Y), its back on the pole's surface
local SWITCH = Vector(0, 6.2, 120)
-- Warm sodium-like yellow, dim enough not to wash out the ground
local LAMP_COLOR = Color(1, 0.7, 0.3)
-- A wide cone down from the head, reaching far (cm), and culled past MAX_DISTANCE from the camera; no shadows, the most expensive part of a light
local LAMP_INTENSITY = 20
local LAMP_RADIUS, LAMP_CONE, LAMP_INNER_CONE = 2600, 80, 20
local MAX_DISTANCE = 7000
-- During Halloween a deep orange, the lens too (MI_ParkLamp_Glow's Color)
local HALLOWEEN_COLOR = Color(1, 0.32, 0.04)
-- The lit lens over the lamp's own while it is on (playground_props.py LampGlow), in the lamp's pivot
local GLOW = "nanos-world::SM_ParkLamp_Glow"

-- The light and its lens go on and off together
local function SetLit(light, glow, is_on)
	if (light:IsValid()) then light:SetVisibility(is_on) end
	if (glow:IsValid()) then glow:SetVisibility(is_on) end
end

Playground.Setup("Lamps", function()
	local color = Playground.theme == "halloween" and HALLOWEEN_COLOR or LAMP_COLOR
	for _, lamp in ipairs(LAMPS) do
		local light = Playground.Track(Light(Playground.At(lamp, HEAD.X, HEAD.Y, HEAD.Z), Rotator(-90, 0, 0), color, LightType.Spot, LAMP_INTENSITY, LAMP_RADIUS, LAMP_CONE, LAMP_INNER_CONE, MAX_DISTANCE, true, false))
		local glow = Playground.Track(StaticMesh(lamp.location, lamp.rotation, GLOW, CollisionType.NoCollision))
		if (Playground.theme == "halloween") then glow:SetMaterialColorParameter("Color", HALLOWEEN_COLOR) end

		-- The switch plate faces its local +Z with its long side along Y: rolled up and turned to face the head's side (the lamp's +Y), the toggle flipping up and down
		if (Playground.HasSandbox()) then
			local location, rotation = Playground.At(lamp, SWITCH.X, SWITCH.Y, SWITCH.Z), Rotator(0, lamp.rotation.Yaw + 180, -90)
			Playground.Button(location, rotation, "turn on", "turn off", function() SetLit(light, glow, true) end, function() SetLit(light, glow, false) end, true, "Switch", true, 1.4)
		end
	end
end)
