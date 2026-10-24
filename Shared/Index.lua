-- Playground map, shared by server and client
--
-- Every position comes from the level: each placeholder the package fills is an actor labelled
-- "<Name>_Spot", exported into Spots.lua by nanos-world-assets/Tools/Playground/export_spots.py

Package.Require("Spots.lua")

Playground = Playground or {}

-- The info stand panel (placeholders.py InfoStand): leans back INFO_TILT degrees, its face centre in the stand's local axes
INFO_TILT = 35
INFO_FACE = Vector(0, 0.8, 100.6)
-- The wall plate's panel (playground_props.py WallPlate): upright, its face centre in the plate's local axes (the pivot is on the wall)
WALL_PLATE_FACE = Vector(0, 5, 0)

-- A spot by name (the actor label without "_Spot"), nil when the level does not have it
function Playground.Spot(name)
	return SPOTS[name]
end

-- All spots whose name starts with prefix, sorted by name so every machine walks them in the same order
-- Info stands and plates ("<Name>_Info", only text is written on them) are left out, so a group's stand is never taken for a member
function Playground.SpotsWith(prefix)
	local names = {}

	for name, spot in pairs(SPOTS) do
		if (name:sub(1, #prefix) == prefix and spot.mesh ~= "InfoStand" and spot.mesh ~= "InfoPlate" and spot.mesh ~= "WallPlate" and spot.mesh ~= "TableSign") then
			names[#names + 1] = name
		end
	end

	table.sort(names)

	local found = {}

	for _, name in ipairs(names) do
		found[#found + 1] = { name = name, spot = SPOTS[name] }
	end

	return found
end

-- A point relative to a spot, in the spot's own axes (X forward, Y right, Z up)
function Playground.At(spot, x, y, z)
	return spot.location + spot.rotation:RotateVector(Vector(x or 0, y or 0, z or 0))
end

-- A point on top of a spot's placeholder (its exported height), lifted further by lift
function Playground.Top(spot, lift)
	return spot.location + Vector(0, 0, spot.top + (lift or 0))
end

-- Yaw a placeholder's front faces: placeholders face their local +Y
function Playground.FrontYaw(spot)
	return spot.rotation.Yaw + 90
end

-- Buttons of the hub's time and weather panel: row 1 sets the time of day, row 2 the weather
SKY_BUTTONS = {
	{ label = "Morning", row = 1, hours = 8, minutes = 0 },
	{ label = "Noon", row = 1, hours = 12, minutes = 0 },
	{ label = "Sunset", row = 1, hours = 18, minutes = 30 },
	{ label = "Night", row = 1, hours = 23, minutes = 0 },
	{ label = "Clear", row = 2, weather = WeatherType.ClearSkies },
	{ label = "Partly", row = 2, weather = WeatherType.PartlyCloudy },
	{ label = "Cloudy", row = 2, weather = WeatherType.Cloudy },
	{ label = "Fog", row = 2, weather = WeatherType.Foggy },
	{ label = "Rain", row = 2, weather = WeatherType.Rain },
	{ label = "Storm", row = 2, weather = WeatherType.RainThunderstorm },
	{ label = "Snow", row = 2, weather = WeatherType.Snow },
}
SKY_ROW_Z = { 125, 50 }                -- button heights on the panel face, from the panel's base
SKY_BUTTON_STEP = 56

-- Where a sky button sits on the panel (its face is the spot's local +Y side, 5 cm out)
function Playground.SkyButtonLocation(panel, button)
	local in_row, index = 0, 0
	for _, b in ipairs(SKY_BUTTONS) do
		if (b.row == button.row) then
			in_row = in_row + 1
			if (b == button) then index = in_row end
		end
	end
	return Playground.At(panel, (index - (in_row + 1) / 2) * SKY_BUTTON_STEP, 5, SKY_ROW_Z[button.row])
end
