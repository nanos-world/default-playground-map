-- Playground map, server side
--
-- The level holds all the geometry and the placeholders; the server only spawns the entities that
-- have to be real for everybody (weapons, vehicles, exhibits, sandbox tools) at the level's spots.
-- Each zone file registers a setup; slots that players can take away are refilled by a respawner

Package.Export("Playground", Playground)

-- Assets only the client loads (exhibit gizmo, the screens' WebUI, SceneCapture and Widget3D, texts), so the server adds them to the ones every client loads while joining
Assets.Precache("nanos-world::BP_TransformGizmoBridge", AssetType.Blueprint)
Assets.Precache("nanos-world::WBP_Empty", AssetType.Blueprint)
Assets.Precache("nanos-world::M_NanosWebUIOpaque", AssetType.Material)
Assets.Precache("nanos-world::M_NanosSceneCapture", AssetType.Material)
Assets.Precache("nanos-world::M_TextFont", AssetType.Material)
Assets.Precache("nanos-world::M_TextFont_Unlit", AssetType.Material)

-- Zone setups, run once the package is loaded
Playground.setups = {}

-- Everything the server spawned, so a reload leaves nothing behind
Playground.entities = {}

-- Refillable slots: { spawn = function() -> entity, entity = current, home = Vector, reach = cm }
Playground.slots = {}

-- Seasonal theme ("halloween": Server/Zones/Halloween.lua), from the "theme" custom setting: a theme name, or "none"; unset or "auto", the theme whose SEASONS dates (month * 100 + day) hold today, if any
-- Read before the zones load, as some of them pick their props by it
local SEASONS = {
	halloween = { 1015, 1102 },
}

local function ReadTheme()
	local value = Server.GetCustomSettings().theme
	if (value ~= nil and value ~= "auto") then return value end
	local now = os.date("*t")
	local today = now.month * 100 + now.day
	for theme, season in pairs(SEASONS) do
		if (today >= season[1] and today <= season[2]) then return theme end
	end
	return "none"
end

Playground.theme = ReadTheme()
-- The clients read it for the sky (Client/Halloween.lua)
Server.SetValue("Playground.Theme", Playground.theme, true)

function Playground.Track(entity)
	Playground.entities[#Playground.entities + 1] = entity

	return entity
end

local DEATH_RESPAWN = 4000

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
			end, DEATH_RESPAWN)
		end)
	end

	return entity
end

-- A slot that is refilled when its entity is destroyed, or carried off and dropped further than reach from home (the dropped one is taken away)
function Playground.Slot(spawn, reach)
	local slot = { spawn = spawn, reach = reach or 1500 }

	-- One broken spawner must not take the rest of its zone down
	if (not Fill(slot)) then return nil end

	slot.home = slot.entity:GetLocation()

	Playground.slots[#Playground.slots + 1] = slot

	return slot
end

-- Something held, attached (a weapon in an inventory), driven or ridden is in use, never take it away from a player
local function IsInUse(entity)
	if (entity.GetHandler and entity:GetHandler()) then return true end
	if (entity.GetAttachedTo and entity:GetAttachedTo()) then return true end
	if (entity.GetPassenger and entity:GetPassenger(0)) then return true end
	return false
end

local function IsAway(slot)
	local entity = slot.entity

	if (not entity or not entity:IsValid()) then return true end
	if (IsInUse(entity)) then return false end

	return entity:GetLocation():Distance(slot.home) > slot.reach
end

function Playground.RefillSlots(force)
	local refilled = 0

	for _, slot in ipairs(Playground.slots) do
		if (force or IsAway(slot)) then
			local old = slot.entity

			-- A carried-off entity nobody uses any more is taken away, so the spot never leaves copies lying around
			if (old and old:IsValid() and (force or not IsInUse(old))) then
				old:Destroy()
			end

			Fill(slot)
			refilled = refilled + 1
		end
	end

	return refilled
end

-- A slot that never leaves a copy behind: once its entity is dropped further than reach away (or destroyed), the refill takes the dropped one away and puts a fresh one back
-- (Playground.Slot keeps carried-off entities where they were left); one held by someone stays theirs
function Playground.ReturningSlot(spawn, reach)
	local current = nil
	return Playground.Slot(function()
		if (current and current:IsValid() and not current:GetHandler()) then current:Destroy() end
		current = spawn()
		return current
	end, reach)
end

-- Melee meshes stand along their local Z from a pivot at the handle's end: the centre of each along Z and along X (the crowbar's hook), and how far
-- its side reaches below the pivot
local MELEE_SHAPES = {
	Knife = { center = 8.5, x = 0, lift = 4 },
	-- NanosWorldWeapons.Crowbar scales SM_Crowbar_01 by 1.5
	Crowbar = { center = 34.4, x = 4.9, lift = 2.6 },
	BaseballBat = { center = 43, x = 0, lift = 3 },
	["nanos-world::SM_Crowbar_01"] = { center = 23, x = 3, lift = 2 },
	["nanos-world::SM_BaseballBat_01"] = { center = 43, x = 0, lift = 3 },
}

-- Where to spawn a melee (shape key: its NanosWorldWeapons name or mesh) lying on its side, centred on center (a point on a surface), handle
-- towards yaw + 90 and blade towards yaw - 90: like the guns on a table of that yaw, grip to the visitor at its front (local +Y)
function Playground.LyingMelee(shape, center, yaw)
	local s = MELEE_SHAPES[shape] or { center = 0, x = 0, lift = 4 }
	-- A -90 roll lays the mesh's Z along -Y (the back) and its Y up
	local rotation = Rotator(0, yaw, -90)
	return center - rotation:RotateVector(Vector(s.x, 0, s.center)) + Vector(0, 0, s.lift), rotation
end

-- A "+1" (or text) that rises from location and fades, for a shot that hit something on the range or a goal; it destroys itself
local SCORE_COLOR = Color(1, 0.8, 0.1)

function Playground.ScorePop(location, text)
	local pop = TextRender(location, Rotator(), text or "+1", 50, SCORE_COLOR, TextRenderRenderingType.UnlitCameraAligned)
	pop:TranslateTo(location + Vector(0, 0, 80), 0.9)
	pop:SetLifeSpan(1)
end

-- Text on the front of a Board spot (placeholders.py Board: panel 400 x 300 from z 60, front face at local +Y 15, all scaled by the spot), x across it (the
-- visitor's left is -x) and z up it in the panel's own cm; for scores and clocks that change while playing, so spawned here and kept in sync for everybody
-- Unlit, its color pre-darkened like Client/Texts.lua's, as the material reads it as sRGB
function Playground.BoardText(spot, x, z, text, size, color)
	local s = spot.scale
	local shown = Color(color.R ^ 2.2, color.G ^ 2.2, color.B ^ 2.2)
	local location = Playground.At(spot, x * s.X, 15 * s.Y + 1, z * s.Z)
	return Playground.Track(TextRender(location, Rotator(0, Playground.FrontYaw(spot), 0), text, size * s.Z, shown, TextRenderRenderingType.Unlit))
end

-- A one-shot sound for everyone near it (Sound only exists on clients), heard up to falloff cm away (2500 when nil), at volume (1 when nil)
function Playground.PlaySound(location, asset, falloff, volume)
	Events.BroadcastRemote("Playground:Sound", Reliability.Unreliable, location, asset, falloff, volume)
end

-- A button at location (its base's pivot) and rotation: a Sandbox LogicButton of style kind ("PushButton", "Lever", "Switch", nil for Classic) with colors, labels
-- and wires. Switchable ones call on_activate and on_deactivate in turns, the others on_activate on every press; is_on starts it activated, scale sizes it,
-- cooldown (ms) is how long it waits after a press before it takes another. Only with Sandbox: callers skip whatever needs a button without it
function Playground.Button(location, rotation, label_on, label_off, on_activate, on_deactivate, switchable, kind, is_on, scale, cooldown)
	local button = Playground.Track(LogicButton(location, rotation, "", "", nil, switchable ~= false, kind))
	button:SetGravityEnabled(false)
	button:SetMassOverride(100000)
	button:SetPhysicsDamping(1000, 1000)
	button:SetActivateLabel(nil, label_on)
	button:SetDeactivateLabel(nil, label_off)
	if (scale and scale ~= 1) then button:SetScale(Vector(scale, scale, scale)) end
	if (cooldown) then button.cooldown = cooldown end

	-- Instance overrides: the base still runs (colors, cooldown, linked entities), then the toy reacts
	button.Activate = function(self, ...)
		LogicButton.Activate(self, ...)
		on_activate()
	end
	button.Deactivate = function(self, ...)
		LogicButton.Deactivate(self, ...)
		if (on_deactivate) then on_deactivate() end
	end

	if (is_on) then button:Activate() end
	return button
end

function Playground.Setup(name, run)
	Playground.setups[#Playground.setups + 1] = { name = name, run = run }
end

Package.Require("Sandbox.lua")

for _, file in pairs(Package.GetFiles("Server/Zones", ".lua")) do
	Package.Require(file)
end

-- Guarded, because it runs both at load time and from the Load event, and either may come first
function Playground.SpawnWorld()
	if (Playground.spawned) then return end
	Playground.spawned = true

	for _, setup in ipairs(Playground.setups) do
		local ok, err = pcall(setup.run)

		if (not ok) then
			Console.Error("Playground: setup '%s' failed: %s", setup.name, tostring(err))
		end
	end

	Console.Log("Playground: %d entities spawned, %d refillable slots. Sandbox %s.",
		#Playground.entities, #Playground.slots, Playground.HasSandbox() and "detected" or "not loaded")
end

Timer.SetInterval(function()
	Playground.RefillSlots(false)
end, 20000)

Console.RegisterCommand("playground_reset", function()
	Console.Log("Playground: %d slots reset.", Playground.RefillSlots(true))
end, "respawns every weapon, vehicle and exhibit of the playground at its spot")

Package.Subscribe("Load", function()
	Playground.SpawnWorld()
end)

Package.Subscribe("Unload", function()
	for _, entity in ipairs(Playground.entities) do
		if (entity and entity:IsValid()) then
			entity:Destroy()
		end
	end

	Playground.entities = {}
	Playground.slots = {}
	Playground.spawned = false
end)

-- Package Load is not guaranteed to fire on the very first load of a map package
Playground.SpawnWorld()
