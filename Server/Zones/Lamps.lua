-- Street lamps: SM_LightPole_A at every lamp spot with a light under its head and, when Sandbox runs, a switch on its pole to turn it on and off

local POLE = "nanos-world::SM_LightPole_A"

-- Squashed to 0.75 of its height (prelude.py LAMP_SCALE)
local POLE_SCALE = Vector(1, 1, 0.75)

-- SM_LightPole_A: pole at the origin, its arm along local +X, the lens (slot "Outside") 187 out with its underside at 813, 610 once squashed
local HEAD = Vector(187, 0, 603)

-- The switch on the pole's front (the arm's side, local +X), its back on the pole's surface
local SWITCH = Vector(10.5, 0, 120)
local SWITCH_SCALE = 1.4

-- The light and its lens go on and off together
local function SetLit(light, pole, is_on)
	if (light:IsValid()) then light:SetVisibility(is_on) end
	if (pole:IsValid()) then pole:SetMaterialScalarParameter("Illum_Intensity", is_on and STREET_LAMP_LENS_GLOW or 0) end
end

local function SpawnLamp(lamp, color)
	local config = STREET_LAMP_LIGHT
	local light = Playground.Track(Light(Playground.At(lamp, HEAD.X, HEAD.Y, HEAD.Z), Rotator(-90, 0, 0), color, LightType.Spot, config.intensity, config.radius, config.cone, config.inner_cone, config.draw_distance, true, true))

	local pole = Playground.Fixed(lamp.location, lamp.rotation, POLE, POLE_SCALE)
	pole:SetMaterialColorParameter("Illum_Color", color)

	SetLit(light, pole, true)

	if (not Playground.HasSandbox()) then return end

	-- The switch plate faces its local +Z with its long side along Y: rolled up and turned to face the arm's side (the lamp's +X), the toggle flipping up and down
	local location, rotation = Playground.At(lamp, SWITCH.X, SWITCH.Y, SWITCH.Z), Rotator(0, lamp.rotation.Yaw + 90, -90)

	Playground.Button(location, rotation, "turn on", "turn off", function() SetLit(light, pole, true) end, function() SetLit(light, pole, false) end, { kind = "Switch", is_on = true, scale = SWITCH_SCALE })
end

Playground.Setup("Lamps", function()
	local color = Playground.theme == "halloween" and HALLOWEEN_LAMP_COLOR or STREET_LAMP_COLOR

	for _, lamp in ipairs(LAMPS or {}) do
		SpawnLamp(lamp, color)
	end
end)
