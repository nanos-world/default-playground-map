-- Physics props: litter bins and the circuit's cones, tyres and barrels the level only shows in the editor (export_spots.py PROPS) and the props on display on the exhibit stands, spawned as real Props so they can be knocked over and carried

-- Museum entities lie on their side with this roll
local LYING_ROLL = 90

-- This high above the top of a spot's stand (a bare marker spot is its own top)
local function AboveTop(spot, lift)
	return spot.mesh == "" and spot.location + Vector(0, 0, lift) or Playground.Top(spot, lift)
end

-- A prop on display on a stand; the museum's are only to look at: nobody grabs them and Sandbox does not break them (MELON #1 stays whole)
local function SpawnExhibitProp(spot, in_museum)
	local still = in_museum and PROPS_MUSEUM_STILL[spot.prop]

	Playground.PropSlot(AboveTop(spot, still or PROPS_EXHIBIT_LIFT), spot.rotation, spot.prop, {
		reach = PROPS_EXHIBIT_REACH,
		mass = PROPS_MASS[spot.prop],
		grab_mode = in_museum and GrabMode.Disabled or nil,
		gravity = not still,
		unbreakable = in_museum
	})
end

-- A sandbox entity on display (the museum's tool guns), lying on its side when it is one of PROPS_MUSEUM_LYING; the museum's are not picked up
local function SpawnExhibitEntity(spot, in_museum)
	local class = Playground.FindClass(spot.entity)
	if (not class) then return end

	local is_lying = in_museum and PROPS_MUSEUM_LYING[spot.entity]
	local location, rotation = AboveTop(spot, PROPS_EXHIBIT_LIFT), spot.rotation

	if (is_lying) then
		location, rotation = Playground.LyingOnSide(spot.entity, AboveTop(spot, 0), spot.rotation + Rotator(0, 0, LYING_ROLL))
	end

	Playground.Slot(function()
		local entity = class(location, rotation)

		if (is_lying) then entity:SetGravityEnabled(false) end

		if (in_museum and entity.SetPickable) then
			entity:SetPickable(false)
			entity:Subscribe("Interact", function() return false end)
		end

		return entity
	end, PROPS_EXHIBIT_REACH)
end

Playground.Setup("Props", function()
	for _, entry in ipairs(PROPS or {}) do
		Playground.PropSlot(entry.location, entry.rotation, entry.asset, {
			reach = PROPS_REACH,
			scale = entry.scale,
			mass = PROPS_MASS[entry.asset]
		})
	end

	-- Museum stands and vitrines (exhibits.py, museum.py) with something on display: a prop, or a sandbox entity when Sandbox runs
	for name, spot in pairs(SPOTS) do
		local in_museum = name:sub(1, 7) == "Museum_"

		if (spot.prop) then
			SpawnExhibitProp(spot, in_museum)
		elseif (spot.entity and Playground.HasSandbox()) then
			SpawnExhibitEntity(spot, in_museum)
		end
	end
end)
