-- Seats: the level's chairs and benches are editor only stand-ins (export_spots.py SEATS); with Sandbox each becomes a sittable Sandbox Chair of its Playground style, without it a plain Prop of the same mesh, so the furniture is there either way

-- Heavy enough that bumping into it does not push it around like a loose prop
local SEAT_MASS = 1000

local function SpawnSeat(seat)
	local seat_type = SEAT_TYPES[seat.mesh]
	local seat_entity = nil

	if (Playground.HasSandbox()) then
		seat_entity = Chair(seat.location, seat.rotation, nil, nil, nil, seat_type.style)

		-- The Chair turns itself to face whoever spawned it, the level's seat already faces where it should
		seat_entity:SetRotation(seat.rotation)
	else
		seat_entity = Prop(seat.location, seat.rotation, seat_type.mesh, CollisionType.Normal, false, GrabMode.Disabled)
	end

	seat_entity:SetMassOverride(SEAT_MASS)

	return seat_entity
end

Playground.Setup("Seats", function()
	for _, seat in ipairs(SEATS or {}) do
		if (SEAT_TYPES[seat.mesh]) then
			Playground.Slot(function() return SpawnSeat(seat) end, SEAT_REACH)
		end
	end
end)
