-- Crows (default-characters' Crow) let loose on the grass by the sports corner and on the vegetable field. Their own AI walks them about, now and then
-- (or when someone comes close, or shoots them) they take off, fly two or three legs high over the map and land wherever the last leg ends
-- One that wandered off further than CROW_REACH from where it started is put back at the next refill, a dead one a few seconds after it dies

-- Spot, how many, how far around its middle they start
local FLOCKS = {
	{ "Sports_Crows", 4, 400 },
	{ "Entities_InstancedStaticMesh", 3, 350 },
}
local CROW_REACH = 8000

Playground.Setup("Crows", function()
	local crow = NanosWorldCharacters and NanosWorldCharacters.Crow
	if (not crow) then return end

	for _, flock in ipairs(FLOCKS) do
		local spot, count, spread = Playground.Spot(flock[1]), flock[2], flock[3]
		if (spot) then
			for _ = 1, count do
				local location = spot.location + Vector(math.random(-spread, spread), math.random(-spread, spread), 30)
				Playground.Slot(function() return crow(location, Rotator(0, math.random(0, 359), 0)) end, CROW_REACH)
			end
		end
	end
end)
