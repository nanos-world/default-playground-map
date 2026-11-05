-- PvP arena (range.py "Range_PvP_*" spots): inside its bounds players can hurt each other, and one who dies in it comes back at one of its spawns, at random, holding a weapon
-- PvP and respawning are Sandbox's (Sandbox.SetCharacterPvPEnabled, Sandbox.RespawnCharacter), so the arena only works with it; with its "enable_pvp" setting on everybody already has PvP and only the respawn changes

local CHARACTER_CLASS_NAMES = { "Character", "CharacterSimple" }

-- The weapon the arena last gave each character
local given = {}

-- A weapon from PVP_WEAPONS in the character's hands; the one given last time is taken away if nobody holds it, so the arena never fills up with them
local function Arm(character)
	local old = given[character]
	if (old and old:IsValid() and not Playground.IsInUse(old)) then old:Destroy() end

	local class = NanosWorldWeapons and NanosWorldWeapons[PVP_WEAPONS[math.random(#PVP_WEAPONS)]]
	if (not class or not character.PickUp) then return end

	local weapon = Playground.Track(class(character:GetLocation(), Rotator()))
	given[character] = weapon
	character:PickUp(weapon)
end

local function SetCharacterPvPEnabled(character, enabled)
	if (character:GetPlayer()) then Sandbox.SetCharacterPvPEnabled(character, enabled) end
end

Playground.Setup("PvP", function()
	local bounds = Playground.Spot("Range_PvP_Bounds")
	local spawns = Playground.SpotsWith("Range_PvP_Spawn")
	if (not bounds or #spawns == 0) then return end

	-- An older Sandbox does not export the hooks
	if (not Playground.HasSandbox() or not Sandbox.SetCharacterPvPEnabled) then return end

	-- The bounds spot's scale is the box's half size
	local arena = Playground.Track(Trigger(bounds.location, bounds.rotation, bounds.scale, TriggerType.Box, false, Color.RED, CHARACTER_CLASS_NAMES))
	arena:Subscribe("BeginOverlap", function(_, character) SetCharacterPvPEnabled(character, true) end)
	arena:Subscribe("EndOverlap", function(_, character) SetCharacterPvPEnabled(character, false) end)

	for _, class in ipairs({ Character, CharacterSimple }) do
		-- Sandbox turns PvP off on a new character right before possessing it, so one spawned in the arena gets it back here
		class.Subscribe("Possess", function(character)
			if (arena:IsOverlapping(character)) then SetCharacterPvPEnabled(character, true) end
		end)

		class.Subscribe("Destroy", function(character)
			given[character] = nil
		end)
	end

	-- A player who dies (or asks to respawn) in the arena comes back at one of its spawns, at random, the rest wherever Sandbox puts them
	local SandboxRespawn = Sandbox.RespawnCharacter

	Sandbox.RespawnCharacter = function(character)
		if (not arena:IsOverlapping(character)) then return SandboxRespawn(character) end

		local spawn = spawns[math.random(#spawns)].spot
		character:Respawn(spawn.location, spawn.rotation)
		Arm(character)
	end

	Package.Subscribe("Unload", function()
		Sandbox.RespawnCharacter = SandboxRespawn
	end)

	-- Sandbox's metal Door at the arena's entrance
	local door = Playground.Spot("Range_PvP_Door")
	if (door) then
		Playground.Track(Door(door.location, door.rotation, nil, nil, nil, "Metal"))
	end
end)
