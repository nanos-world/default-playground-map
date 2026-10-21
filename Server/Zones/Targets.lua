-- Free-standing targets: the level's target stand-ins (every spot of a Target mesh: paper, steel silhouette, gong, popper) become Sandbox's Target entity,
-- with the plate of that spot's mesh (the entity clangs and pops a "+1" on hits by itself); the shooting range's are its game's own (Range.lua)

Playground.Setup("Targets", function()
	if (not Playground.HasSandbox() or not Target) then return end

	for name, spot in pairs(SPOTS) do
		if (spot.mesh:sub(1, 6) == "Target" and spot.asset and name:sub(1, 6) ~= "Range_") then
			-- The entity turns itself +90 yaw, the spots already hold the plate's final yaw
			Playground.Track(Target(spot.location, Rotator(0, spot.rotation.Yaw - 90, 0), spot.mesh))
		end
	end
end)
