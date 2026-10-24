-- default-vehicles' classes parked in each row of bays (the spots starting with the row's prefix), spread evenly over the row: the long ones take the deep bays of the west row
CAR_PARK_ROWS = {
	{
		prefix = "South_Bay",
		vehicles = { "Offroad", "SUV", "Sedan", "Hatchback", "Pickup", "SportsCar", "Wagon" }
	},
	{
		prefix = "South_TruckBay",
		vehicles = { "Van", "CamperVan", "TruckBox", "TruckChassis" }
	}
}

-- A vehicle left further than this from its bay gets a fresh one in the bay
CAR_PARK_REACH = 5000
