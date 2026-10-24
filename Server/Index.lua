-- Playground map, server side
-- The level holds all the geometry and the placeholders; the server only spawns the entities that have to be real for everybody (weapons, vehicles, exhibits, sandbox tools) at the level's spots
-- Each zone file (Server/Zones) registers a setup; slots that players can take away are refilled by a respawner (Slots.lua)

-- Exposes Playground to other packages
Package.Export("Playground", Playground)

-- Assets only the client loads (exhibit gizmo, the screens' WebUI, SceneCapture and Widget3D, texts), so the server adds them to the ones every client loads while joining
Assets.Precache("nanos-world::BP_TransformGizmoBridge", AssetType.Blueprint)
Assets.Precache("nanos-world::WBP_Empty", AssetType.Blueprint)
Assets.Precache("nanos-world::M_NanosWebUIOpaque", AssetType.Material)
Assets.Precache("nanos-world::M_NanosSceneCapture", AssetType.Material)
Assets.Precache("nanos-world::M_TextFont", AssetType.Material)
Assets.Precache("nanos-world::M_TextFont_Unlit", AssetType.Material)

-- Seasonal themes by name, with the dates (month * 100 + day) they run between when the theme is picked automatically
local SEASONS = {
	halloween = { 1015, 1102 }
}

-- Seasonal theme ("halloween": Server/Zones/Halloween.lua), from the "theme" custom setting: a theme name, or "none"; unset or "auto", the theme whose SEASONS dates hold today, if any
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

-- Read before the configs and zones load, as some of them pick their props by it
Playground.theme = ReadTheme()

-- The clients read it for the sky (Client/Halloween.lua)
Server.SetValue("Playground.Theme", Playground.theme, true)

-- Zone setups, run once the package is loaded
Playground.setups = {}

function Playground.Setup(name, run)
	Playground.setups[#Playground.setups + 1] = { name = name, run = run }
end

-- Loads Package Files
Package.Require("SandboxBridge.lua")
Package.Require("Slots.lua")
Package.Require("Helpers.lua")

RequireAllLuaFilesInFolder("Server/Config")
RequireAllLuaFilesInFolder("Server/Zones")

-- Runs every zone setup once; guarded, because it runs both at load time and from the Load event, and either may come first
function Playground.SpawnWorld()
	if (Playground.spawned) then return end
	Playground.spawned = true

	for _, setup in ipairs(Playground.setups) do
		local ok, err = pcall(setup.run)

		if (not ok) then
			Console.Error("Playground: setup '%s' failed: %s", setup.name, tostring(err))
		end
	end

	Console.Log("Playground: %d entities spawned, %d refillable slots. Sandbox %s.", #Playground.entities, #Playground.slots, Playground.HasSandbox() and "detected" or "not loaded")
end

-- Puts back whatever players carried away from its spot
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
	Playground.DestroyAll()
	Playground.spawned = false
end)

-- Package Load is not guaranteed to fire on the very first load of a map package
Playground.SpawnWorld()
