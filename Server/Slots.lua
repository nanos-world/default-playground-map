-- Refillable slots: an entity at its spot that comes back when it is destroyed, or carried off and dropped further than reach from home
-- Each slot is { spawn = function() -> entity, entity = current, home = Vector, reach = cm }

-- Everything the server spawned, so a reload leaves nothing behind
Playground.entities = {}

-- Every refillable slot
Playground.slots = {}

-- A slot without its own reach gets this one
local DEFAULT_REACH = 1500

-- A dead character is replaced this long (ms) after it dies
local CHARACTER_RESPAWN = 4000

function Playground.Track(entity)
	Playground.entities[#Playground.entities + 1] = entity

	return entity
end

-- Destroys everything the server spawned and forgets every slot
function Playground.DestroyAll()
	for _, entity in ipairs(Playground.entities) do
		if (entity and entity:IsValid()) then
			entity:Destroy()
		end
	end

	Playground.entities = {}
	Playground.slots = {}
end

-- Spawns the slot's entity again; a dead character is replaced a few seconds after it dies
local function Fill(slot)
	local ok, entity = pcall(slot.spawn)
	if (not ok or not entity) then
		Console.Warn("Playground: a slot failed to spawn: %s", tostring(entity))
		slot.entity = nil
		return nil
	end

	slot.entity = Playground.Track(entity)

	if (entity:IsA(Character) or entity:IsA(CharacterSimple)) then
		entity:Subscribe("Death", function(self)
			Timer.SetTimeout(function()
				if (slot.entity ~= self or not Playground.spawned) then return end
				if (self:IsValid()) then self:Destroy() end
				Fill(slot)
			end, CHARACTER_RESPAWN)
		end)
	end

	return entity
end

-- A slot that is refilled when its entity is destroyed, or carried off and dropped further than reach (DEFAULT_REACH when nil) from home: the dropped one is taken away
function Playground.Slot(spawn, reach)
	local slot = { spawn = spawn, reach = reach or DEFAULT_REACH }

	-- One broken spawner must not take the rest of its zone down
	if (not Fill(slot)) then return nil end

	slot.home = slot.entity:GetLocation()

	Playground.slots[#Playground.slots + 1] = slot

	return slot
end

-- Whether anyone sits in the vehicle, driver or passenger
local function IsOccupied(vehicle)
	for _, passenger in pairs(vehicle:GetPassengers() or {}) do
		if (passenger and passenger:IsValid()) then return true end
	end

	return false
end

-- Something held, attached (a weapon in an inventory), driven or ridden is in use, never take it away from a player
function Playground.IsInUse(entity)
	if (entity.GetHandler and entity:GetHandler()) then return true end
	if (entity.GetAttachedTo and entity:GetAttachedTo()) then return true end
	if (entity.GetPassengers and IsOccupied(entity)) then return true end

	return false
end

local function IsAway(slot)
	local entity = slot.entity

	if (not entity or not entity:IsValid()) then return true end
	if (Playground.IsInUse(entity)) then return false end

	return entity:GetLocation():Distance(slot.home) > slot.reach
end

-- Refills every slot whose entity is gone or was left away from home (every slot when forced); returns how many it refilled
function Playground.RefillSlots(force)
	local refilled = 0

	for _, slot in ipairs(Playground.slots) do
		if (force or IsAway(slot)) then
			local old = slot.entity

			-- A carried-off entity nobody uses any more is taken away, so the spot never leaves copies lying around
			if (old and old:IsValid() and (force or not Playground.IsInUse(old))) then
				old:Destroy()
			end

			Fill(slot)
			refilled = refilled + 1
		end
	end

	return refilled
end

-- Takes the slot's entity away (wherever it is) and spawns a fresh one at home; returns it, or nil when keep_in_use is set and someone uses it
function Playground.Respawn(slot, keep_in_use)
	local old = slot.entity

	if (old and old:IsValid()) then
		if (keep_in_use and Playground.IsInUse(old)) then return nil end
		old:Destroy()
	end

	return Fill(slot)
end
