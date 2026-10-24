-- Halloween decor, only while the theme is on (Playground.theme "halloween", Server/Index.lua): halloween.py's "Halloween_*" spots, hidden in the level, filled here
-- Halloween_Lantern* are carved pumpkins (SM_Pumpkin_Carved_0*), props to kick about; any other spot its own mesh (the graveyards' SM_Grave_*, the scarecrow)
-- The sky is the client's (Client/Halloween.lua); the lamps turn orange (Lamps.lua) and the entities field grows pumpkins (Entities.lua)

-- The carved pumpkins, one picked for each lamp (SM_Pumpkin_Carved_03 is a plain one)
local CARVED = { "nanos-world::SM_Pumpkin_Carved_00", "nanos-world::SM_Pumpkin_Carved_01", "nanos-world::SM_Pumpkin_Carved_02" }
-- One more carved pumpkin at the foot of every street lamp, beside its pole, in the lamp's own axes
local LAMP_LANTERN = Vector(-15, -35, 0)

-- Their faces look along local +X, the way the lamp's arm points
local FACE_YAW = 0
-- A pumpkin kicked further than this from its spot is put back on the next refill
local PUMPKIN_REACH = 1500

local function Pumpkin(location, rotation, asset)
	Playground.Slot(function()
		return Prop(location + Vector(0, 0, 1), rotation, asset, CollisionType.Normal, true, GrabMode.Enabled)
	end, PUMPKIN_REACH)
end

Playground.Setup("Halloween", function()
	if (Playground.theme ~= "halloween") then return end

	for _, entry in ipairs(Playground.SpotsWith("Halloween_")) do
		local spot = entry.spot
		-- Each goes by its stand-in's asset, registered in core under its own name
		local asset = spot.asset and spot.asset:match("[^/]+$") or ""
		if (asset:sub(1, 18) == "SM_Pumpkin_Carved_") then
			Pumpkin(spot.location, spot.rotation, "nanos-world::" .. asset)
		elseif (asset ~= "") then
			Playground.Track(StaticMesh(spot.location, spot.rotation, "nanos-world::" .. asset, CollisionType.Normal))
		end
	end

	for k, lamp in ipairs(LAMPS) do
		local asset = CARVED[(k - 1) % #CARVED + 1]
		Pumpkin(Playground.At(lamp, LAMP_LANTERN.X, LAMP_LANTERN.Y, LAMP_LANTERN.Z), Rotator(0, lamp.rotation.Yaw + FACE_YAW + math.random(-20, 20), 0), asset)
	end
end)
