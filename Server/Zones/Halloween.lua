-- Halloween decor, only while the theme is on (Playground.theme "halloween", Server/Index.lua): halloween.py's "Halloween_*" spots, hidden in the level, filled here
-- Halloween_Lantern* are carved pumpkins (SM_Pumpkin_Carved_0*), props to kick about; any other spot gets its own mesh (the graveyards' SM_Grave_*, the scarecrow)
-- The sky is the client's (Client/Halloween.lua); the lamps turn orange (Lamps.lua) and the entities field grows pumpkins (Entities.lua)

-- The pumpkins' faces look along local +X, the way the lamp's arm points
local FACE_YAW = 0

local function Pumpkin(location, rotation, asset)
	Playground.PropSlot(location + Vector(0, 0, 1), rotation, asset, { reach = HALLOWEEN_PUMPKIN_REACH })
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
			Playground.Fixed(spot.location, spot.rotation, "nanos-world::" .. asset)
		end
	end

	for k, lamp in ipairs(LAMPS or {}) do
		local asset = HALLOWEEN_CARVED[(k - 1) % #HALLOWEEN_CARVED + 1]
		local location = Playground.At(lamp, HALLOWEEN_LAMP_LANTERN.X, HALLOWEEN_LAMP_LANTERN.Y, HALLOWEEN_LAMP_LANTERN.Z)

		Pumpkin(location, Rotator(0, lamp.rotation.Yaw + FACE_YAW + math.random(-20, 20), 0), asset)
	end
end)
