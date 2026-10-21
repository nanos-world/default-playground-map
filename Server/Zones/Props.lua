-- Physics props: litter bins and the circuit's cones, tyres and barrels the level only shows in the editor (export_spots.py PROPS) and the props on display on the exhibit stands, spawned as real Props so they can be knocked over and carried

-- A prop dragged further than this from its spot is put back on the next refill
local REACH = 2500

-- Exhibits are dropped from this high above their stand's top, so they settle on it instead of starting inside it
local EXHIBIT_LIFT = 15
-- An exhibit carried further than this from its stand is put back on it on the next refill
local EXHIBIT_REACH = 600

-- Museum props held still instead of dropped (a melon rolls off-centre): how high their pivot sits above what they rest on
local MUSEUM_STILL = { ["nanos-world::SM_Fruit_Watermelon_01"] = 14 }
-- Museum entities (the tool guns) laid on their side and held there, gravity off: their spot is where the middle of the gun lies on the case floor.
-- Per class, the centre of its mesh's bounds from its pivot and its half thickness (SK_ToolGun, SK_GravityGun bounds)
local MUSEUM_LYING_ROLL = 90
local MUSEUM_LYING = {
	WeldGun = { centre = Vector(12.85, 0, 6.33), half = 4.5 },
	PhysicsGun = { centre = Vector(15.92, 0, 5.81), half = 8.04 },
}

-- Light circuit dressing: a car pushes a cone or tyre aside instead of riding up on it and getting stuck (the mass from the mesh's volume was heavy
-- enough to wedge under a car); a few kg, not less, or the car to prop mass ratio makes the physics jitter
local MASS = { ["nanos-world::SM_ConstructionPylons_05"] = 4, ["nanos-world::SM_TireLarge"] = 12 }

-- A refillable prop that never leaves a copy behind: refilling takes the old one away instead of leaving it wherever it was dropped
local function PropSlot(location, rotation, asset, reach, grab_mode, still, unbreakable, scale)
	local current = nil

	Playground.Slot(function()
		if (current and current:IsValid() and not current:GetHandler()) then
			current:Destroy()
		end

		current = Prop(location, rotation, asset, CollisionType.Normal, true, grab_mode or GrabMode.Enabled)
		if (scale) then current:SetScale(scale) end
		if (MASS[asset]) then current:SetMassOverride(MASS[asset]) end
		if (still) then current:SetGravityEnabled(false) end
		if (unbreakable) then current:SetValue("Unbreakable", true) end
		return current
	end, reach or REACH)
end

-- This high above the top of a spot's stand (a bare marker spot is its own top)
local function AboveTop(spot, lift)
	return spot.mesh == "" and spot.location + Vector(0, 0, lift) or Playground.Top(spot, lift)
end

Playground.Setup("Props", function()
	for _, entry in ipairs(PROPS or {}) do
		PropSlot(entry.location, entry.rotation, entry.asset, nil, nil, nil, nil, entry.scale)
	end

	-- Museum stands and vitrines (exhibits.py, museum.py) with something on display: a prop, or a sandbox entity (the museum's tool guns) when Sandbox runs;
	-- the museum's are only to look at, nobody grabs or picks them up
	for name, spot in pairs(SPOTS) do
		local in_museum = name:sub(1, 7) == "Museum_"
		if (spot.prop) then
			local still = in_museum and MUSEUM_STILL[spot.prop]
			-- The museum's are on display: Sandbox does not break them (MELON #1 stays whole)
			PropSlot(AboveTop(spot, still or EXHIBIT_LIFT), spot.rotation, spot.prop, EXHIBIT_REACH, in_museum and GrabMode.Disabled or nil, still, in_museum)
		elseif (spot.entity and Playground.HasSandbox()) then
			local class = Playground.FindClass(spot.entity)
			if (class) then
				local lying = in_museum and MUSEUM_LYING[spot.entity]
				local location, rotation = AboveTop(spot, EXHIBIT_LIFT), spot.rotation
				if (lying) then
					rotation = spot.rotation + Rotator(0, 0, MUSEUM_LYING_ROLL)
					location = AboveTop(spot, lying.half) - rotation:RotateVector(lying.centre)
				end
				Playground.Slot(function()
					local entity = class(location, rotation)
					if (lying) then entity:SetGravityEnabled(false) end
					if (in_museum and entity.SetPickable) then
						entity:SetPickable(false)
						entity:Subscribe("Interact", function() return false end)
					end
					return entity
				end, EXHIBIT_REACH)
			end
		end
	end
end)
