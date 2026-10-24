-- Food on the picnic tables (export_spots.py TABLES, and the lake's table around its jukebox): fruit, pizza and bread that break apart like Sandbox's breakables when they are hit, thrown or shot (Sandbox breaks every prop of its breakable meshes)

local function SetTable(location, rotation, top, places)
	for _, x in ipairs(places) do
		local at = location + rotation:RotateVector(Vector(x, math.random(-15, 15), top + 3))

		-- A new pick lands on the table at each refill
		Playground.Slot(function()
			return Prop(at, Rotator(0, math.random(0, 359), 0), FOOD_ASSETS[math.random(#FOOD_ASSETS)], CollisionType.Normal, true, GrabMode.Enabled)
		end, FOOD_REACH)
	end
end

Playground.Setup("Food", function()
	for _, picnic in ipairs(TABLES or {}) do
		SetTable(picnic.location, picnic.rotation, picnic.top, FOOD_PLACES)
	end

	for name, spot in pairs(SPOTS) do
		if (spot.mesh == "Picnic" and name:sub(-8) == "_Jukebox") then
			SetTable(spot.location, Rotator(0, spot.rotation.Yaw, 0), spot.top, FOOD_JUKEBOX_PLACES)
		end
	end
end)
