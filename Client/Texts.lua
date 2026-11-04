-- Every informative text of the playground, drawn with TextRender on the level's boards and stands (the words are in Client/Config/Texts.lua)
-- Keyed by spot name, so moving a stand in the level moves its text with it; info stands outside the museum carry their text in the level itself (spot.info, set by the generators)

local INK = Color(0, 0, 0)
local PURPLE = Color(0.35, 0.1, 0.8)

-- A title's capitals run about this wide per letter, in parts of its size; a long one on a Board shrinks to the panel's width less a margin
local LETTER_W = 0.62
local BOARD_TITLE_W = 360

-- An info stand's title alone fits about this many letters at full size, and keeps its zone's hue but no channel above INFO_TITLE_MAX, or a light one (yellow, orange) can't be read on the white panel
local INFO_TITLE_FIT = 15
local INFO_TITLE_MAX = 0.4

-- An info stand's web addresses fit this width of the 72 cm panel, lower case letters running about LINK_LETTER_W of their size each
local INFO_LINK_W = 68
local LINK_LETTER_W = 0.52

local function WelcomeControls()
	local lines = { "CONTROLS" }

	for _, control in ipairs(WELCOME_CONTROLS) do
		local key = control.binding and Input.GetMappedKeys(control.binding)[1] or nil
		key = key and (KEY_NAMES[key] or key) or control.fallback

		if (key) then lines[#lines + 1] = control.label .. ": " .. key end
	end

	return table.concat(lines, "\n")
end

-- Black text is unlit, or the sun washes the letters out on the bright panels and they reflect like the paper; coloured text (titles) is lit instead, as an unlit colour is emissive and glows at night
local function Text(location, rotation, text, size, color)
	local is_black = color.R + color.G + color.B == 0

	return Playground.Keep(TextRender(location, rotation, text, size, Playground.TextColor(color), is_black and TextRenderRenderingType.Unlit or TextRenderRenderingType.Lit))
end

-- A title and its body on a Board spot; with a second body, the two share the panel as columns (the visitor's left is local -X)
local function BoardText(spot, title, body, title_size, body_size, body_right)
	local s = spot.scale
	local front = Rotator(0, Playground.FrontYaw(spot), 0)
	local face = BOARD_FACE * s.Y + 1
	local top = (BOARD_BASE_Z + BOARD_HEIGHT) * s.Z
	local column = body_right and 100 * s.X or 0
	local size = math.min(title_size * s.Z, BOARD_TITLE_W * s.X / (#title * LETTER_W))

	Text(Playground.At(spot, 0, face, top - 55 * s.Z), front, title, size, INK)
	Text(Playground.At(spot, -column, face, top - 185 * s.Z), front, body, body_size * s.Z, INK)

	if (body_right) then
		Text(Playground.At(spot, column, face, top - 185 * s.Z), front, body_right, body_size * s.Z, INK)
	end
end

local function Darkened(color)
	local k = math.min(1, INFO_TITLE_MAX / math.max(color.R, color.G, color.B, 0.001))

	return Color(color.R * k, color.G * k, color.B * k)
end

-- A title and body on an info stand, plate, table sign or wall plate; with link (web addresses, one per line) the title and body move up and the addresses
-- go underneath, as big as the longest one allows on the panel's width
local function InfoText(spot, title, body, color, link)
	-- Stands, plates and table signs share the leaning panel, a wall plate's stands upright
	local tilt, face = INFO_TILT, INFO_FACE
	if (spot.mesh == "WallPlate") then tilt, face = 0, WALL_PLATE_FACE end

	local rotation = Rotator(tilt, Playground.FrontYaw(spot), 0)
	local up = Vector(0, -math.sin(math.rad(tilt)), math.cos(math.rad(tilt)))

	-- Lifted off the panel along its normal, or the letters sink into the surface
	local normal = Vector(0, math.cos(math.rad(tilt)), math.sin(math.rad(tilt)))

	-- Stands are scaled uniformly (the small ones in front of the tool tables), the text scales with them
	local s = spot.scale
	local k = math.min(s.X, s.Z)
	local function Scaled(v) return Vector(v.X * s.X, v.Y * s.Y, v.Z * s.Z) end

	if (not body or body == "") then
		-- A title alone (a stall's board): centred, as tall as half the panel and no wider than it (72 x 48 unscaled)
		local at = Scaled(face + normal * 1.5)
		local size = math.min(24 * s.Z, 72 * s.X * 0.85 / (LETTER_W * #title))

		Text(Playground.At(spot, at.X, at.Y, at.Z), rotation, title, size, Darkened(color or PURPLE))
		return
	end

	local title_up, body_up = 12, -6
	if (link) then title_up, body_up = 15, 1 end

	local title_at, body_at = Scaled(face + normal * 1.5 + up * title_up), Scaled(face + normal * 1.5 + up * body_up)

	-- Long titles shrink to the width of about INFO_TITLE_FIT letters at full size, so they stay on the panel
	local fit = math.min(1, INFO_TITLE_FIT / #title)

	Text(Playground.At(spot, title_at.X, title_at.Y, title_at.Z), rotation, title, 8.5 * k * fit, Darkened(color or PURPLE))
	Text(Playground.At(spot, body_at.X, body_at.Y, body_at.Z), rotation, body, 5.5 * k, INK)

	if (link) then
		local longest = 0
		for line in link:gmatch("[^\n]+") do longest = math.max(longest, #line) end

		local link_at = Scaled(face + normal * 1.5 - up * 16)
		Text(Playground.At(spot, link_at.X, link_at.Y, link_at.Z), rotation, link, math.min(4 * k, INFO_LINK_W * s.X / (LINK_LETTER_W * longest)), Darkened(color or PURPLE))
	end
end

-- The labels of the hub's time and weather panel (its buttons are the server's)
local function SkyPanelText(panel)
	local front = Rotator(0, Playground.FrontYaw(panel), 0)

	Text(Playground.At(panel, 0, 6, 172), front, "TIME & WEATHER", 16, INK)

	for _, button in ipairs(HUB_SKY_BUTTONS) do
		Text(Playground.SkyButtonLocation(panel, button) + front:RotateVector(Vector(1, 0, 0)) - Vector(0, 0, 32), front, button.label, 9, INK)
	end
end

function Playground.SpawnTexts()
	for name, info in pairs(EXHIBIT_INFO) do
		local spot = Playground.Spot("Entities_" .. name .. "_Info")
		if (spot) then InfoText(spot, info.title, info.body, spot.color) end
	end

	-- A Board spot with info (the range's weapons board) gets the board's layout, in smaller print than the hub's intros
	for _, spot in pairs(SPOTS) do
		if (spot.info and spot.mesh == "Board") then
			BoardText(spot, spot.info.title, spot.info.body, 40, 13)
		elseif (spot.info) then
			InfoText(spot, spot.info.title, spot.info.body, spot.color, spot.info.link)
		end
	end

	for zone, info in pairs(ZONE_INTRO) do
		local spot = Playground.Spot("Hub_Intro_" .. zone)
		if (spot) then BoardText(spot, info.title, info.body, 48, 26) end
	end

	local welcome = Playground.Spot("Hub_Board_Welcome")
	if (welcome) then BoardText(welcome, WELCOME_TITLE, WELCOME_ABOUT, 36, 13, WelcomeControls()) end

	local panel = Playground.Spot("Hub_SkyPanel")
	if (panel) then SkyPanelText(panel) end
end
