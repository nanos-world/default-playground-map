-- Car park and lake: one of each wheeled vehicle in the bays, boats moored at the pier, and a button that brings every car nobody sits in back to its bay

local CARS = { "Offroad", "SUV", "Sedan", "Hatchback", "Pickup", "SportsCar", "Wagon" }
-- The long ones take the deep bays of the west row
local LONG_VEHICLES = { "Van", "CamperVan", "TruckBox", "TruckChassis" }
local VEHICLE_REACH = 5000             -- a vehicle left further than this from its bay gets a fresh one in the bay

-- Whether anyone sits in the vehicle, driver or passenger
local function IsOccupied(vehicle)
	for _, passenger in pairs(vehicle:GetPassengers() or {}) do
		if (passenger and passenger:IsValid()) then return true end
	end
	return false
end

-- Takes the slot's car away (unless someone is in it) and puts a fresh one in its bay
local function Respawn(slot)
	local car = slot.entity
	if (car and car:IsValid()) then
		if (IsOccupied(car)) then return end
		car:Destroy()
	end
	local ok, fresh = pcall(slot.spawn)
	slot.entity = ok and fresh and Playground.Track(fresh) or nil
end

Playground.Setup("CarPark", function()
	if (not NanosWorldVehicles) then
		Console.Warn("Playground: default-vehicles not loaded, the car park stays empty")
		return
	end

	local car_slots = {}

	for prefix, names in pairs({ South_Bay = CARS, South_TruckBay = LONG_VEHICLES }) do
		local bays = Playground.SpotsWith(prefix)

		for i, name in ipairs(names) do
			-- Spread evenly over the row's bays, leaving free bays between them
			local bay, class = bays[math.floor((i - 1) * #bays / #names) + 1], NanosWorldVehicles[name]

			if (bay and class) then
				local location, rotation = bay.spot.location + Vector(0, 0, 60), bay.spot.rotation
				car_slots[#car_slots + 1] = Playground.Slot(function() return class(location, rotation) end, VEHICLE_REACH)
			end
		end
	end

	local button = Playground.Spot("South_CarRespawnButton")
	if (button and Playground.HasSandbox()) then
		Playground.Button(Playground.Top(button, 0), Rotator(0, button.rotation.Yaw, 0), "respawn cars", "respawn cars", function()
			for _, slot in ipairs(car_slots) do
				Respawn(slot)
			end
		end, nil, false, "PushButton")
	end

	for _, entry in ipairs(Playground.SpotsWith("South_Boat")) do
		local location, rotation = entry.spot.location + Vector(0, 0, 30), entry.spot.rotation
		Playground.Slot(function() return NanosWorldVehicles.Boat(location, rotation) end, VEHICLE_REACH)
	end
end)
