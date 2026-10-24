-- Seats: the level's chairs and benches are editor only stand-ins (export_spots.py SEATS). With Sandbox each becomes a sittable Sandbox Chair of its
-- Playground style, held still where it stands; without it a plain Prop of the same mesh, so the furniture is there either way

-- Sandbox Chair style and mesh per stand-in (prelude.py SEAT_PROPS name)
local STYLES = { Chair = "PlaygroundChair", Bench = "PlaygroundBench", WoodenChair = "Wooden" }
local MESHES = { Chair = "nanos-world::SM_PG_Chair", Bench = "nanos-world::SM_PG_Bench", WoodenChair = "nanos-world::SM_WoodenChair" }

-- One shoved further than this from its spot (the physics gun) is put back on the next refill
local REACH = 300

-- Stays where the level put it like any furniture: gravity off, too heavy and damped to be pushed around
local function HoldStill(prop)
	prop:SetMassOverride(1000)
	return prop
end

Playground.Setup("Seats", function()
	local chair_class = Playground.HasSandbox() and Playground.FindClass("Chair", { Prop })

	for _, seat in ipairs(SEATS or {}) do
		Playground.Slot(function()
			if (chair_class) then
				local chair = chair_class(seat.location, seat.rotation, nil, nil, nil, STYLES[seat.mesh])

				-- The Chair turns itself to face whoever spawned it, the level's seat already faces where it should
				chair:SetRotation(seat.rotation)
				return HoldStill(chair)
			end

			return HoldStill(Prop(seat.location, seat.rotation, MESHES[seat.mesh], CollisionType.Normal, false, GrabMode.Disabled))
		end, REACH)
	end
end)
