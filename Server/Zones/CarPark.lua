-- Car park and lake: one of each wheeled vehicle in the bays, boats moored at the pier, and a button that brings every car nobody sits in back to its bay

-- Vehicles spawn this high above their bay or mooring, to settle
local CAR_LIFT = 60
local BOAT_LIFT = 30

Playground.Setup("CarPark", function()
	if (not NanosWorldVehicles) then
		Console.Warn("Playground: default-vehicles not loaded, the car park stays empty")
		return
	end

	local car_slots = {}

	for _, row in ipairs(CAR_PARK_ROWS) do
		local bays = Playground.SpotsWith(row.prefix)

		for i, name in ipairs(row.vehicles) do
			-- Spread evenly over the row's bays, leaving free bays between them
			local bay, class = bays[math.floor((i - 1) * #bays / #row.vehicles) + 1], NanosWorldVehicles[name]

			if (bay and class) then
				local location, rotation = bay.spot.location + Vector(0, 0, CAR_LIFT), bay.spot.rotation
				car_slots[#car_slots + 1] = Playground.Slot(function() return class(location, rotation) end, CAR_PARK_REACH)
			end
		end
	end

	for _, entry in ipairs(Playground.SpotsWith("South_Boat")) do
		local location, rotation = entry.spot.location + Vector(0, 0, BOAT_LIFT), entry.spot.rotation
		Playground.Slot(function() return NanosWorldVehicles.Boat(location, rotation) end, CAR_PARK_REACH)
	end

	-- Takes every car away (unless someone is in it) and puts a fresh one in its bay
	local button = Playground.Spot("South_CarRespawnButton")
	if (button and Playground.HasSandbox()) then
		Playground.PushButton(button, "respawn cars", function()
			for _, slot in ipairs(car_slots) do
				Playground.Respawn(slot, true)
			end
		end)
	end
end)
