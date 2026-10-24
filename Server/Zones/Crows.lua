-- Crows (default-characters' Crow) let loose on the grass by the sports corner and on the vegetable field: their own AI walks them about, now and then (or when someone comes close, or shoots them) they take off, fly two or three legs high over the map and land wherever the last leg ends
-- One that wandered off further than CROW_REACH is put back at the next refill, a dead one a few seconds after it dies

Playground.Setup("Crows", function()
	local crow = NanosWorldCharacters and NanosWorldCharacters.Crow
	if (not crow) then return end

	for _, flock in ipairs(CROW_FLOCKS) do
		local spot = Playground.Spot(flock.spot)

		if (spot) then
			for _ = 1, flock.count do
				local location = spot.location + Vector(math.random(-flock.spread, flock.spread), math.random(-flock.spread, flock.spread), 30)
				Playground.Slot(function() return crow(location, Rotator(0, math.random(0, 359), 0)) end, CROW_REACH)
			end
		end
	end
end)
