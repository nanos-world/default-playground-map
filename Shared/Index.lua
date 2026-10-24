-- Playground map, shared by server and client
-- Every position comes from the level: each placeholder the package fills is an actor labelled "<Name>_Spot", exported into Spots.lua by nanos-world-assets/Tools/Playground/export_spots.py

-- Global table to store Playground related functions and variables, exported to other packages by the server
Playground = Playground or {}

-- Helper to load all files in a folder
function RequireAllLuaFilesInFolder(folder)
	local files = Package.GetFiles(folder, ".lua")
	for _, file in pairs(files) do
		Package.Require(file)
	end
end

Package.Require("Spots.lua")

-- The info stand panel (placeholders.py InfoStand): leans back INFO_TILT degrees, its face centre in the stand's local axes
INFO_TILT = 35
INFO_FACE = Vector(0, 0.8, 100.6)

-- The wall plate's panel (playground_props.py WallPlate): upright, its face centre in the plate's local axes (the pivot is on the wall)
WALL_PLATE_FACE = Vector(0, 5, 0)

-- The Board placeholder (placeholders.py Board): a panel BOARD_WIDTH x BOARD_HEIGHT from BOARD_BASE_Z up, its front face at local +Y BOARD_FACE, all scaled by the spot
BOARD_WIDTH = 400
BOARD_HEIGHT = 300
BOARD_BASE_Z = 60
BOARD_FACE = 15

-- A spot by name (the actor label without "_Spot"), nil when the level does not have it
function Playground.Spot(name)
	return SPOTS[name]
end

-- Info stands and plates only have text written on them, so a group's stand is never taken for one of its members
local INFO_MESHES = {
	InfoStand = true,
	InfoPlate = true,
	WallPlate = true,
	TableSign = true
}

-- All spots whose name starts with prefix (info stands left out), sorted by name so every machine walks them in the same order
function Playground.SpotsWith(prefix)
	local names = {}

	for name, spot in pairs(SPOTS) do
		if (name:sub(1, #prefix) == prefix and not INFO_MESHES[spot.mesh]) then
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

-- TextRender's material reads the color as sRGB bytes back as linear, which lifts it (0.05 shows as 0.25 grey): pre-darkened, it shows as given
function Playground.TextColor(color)
	return Color(color.R ^ 2.2, color.G ^ 2.2, color.B ^ 2.2)
end

-- Where a sky button sits on the hub's time and weather panel (its face is the spot's local +Y side, 5 cm out)
function Playground.SkyButtonLocation(panel, button)
	local in_row, index = 0, 0

	for _, other in ipairs(HUB_SKY_BUTTONS) do
		if (other.row == button.row) then
			in_row = in_row + 1
			if (other == button) then index = in_row end
		end
	end

	return Playground.At(panel, (index - (in_row + 1) / 2) * HUB_SKY_BUTTON_STEP, 5, HUB_SKY_ROW_Z[button.row])
end

-- Load all configs both sides read
RequireAllLuaFilesInFolder("Shared/Config")
