-- Playground map, client side: what only the clients spawn (exhibits of client-only classes, texts, sounds) and the Halloween sky

-- Everything the client spawned, so a reload leaves nothing behind
local spawned = {}

function Playground.Keep(entity)
	spawned[#spawned + 1] = entity

	return entity
end

Events.SubscribeRemote("Playground:Error", function(message)
	Client.ShowNotification(message, NotificationType.Error, false, 3)
end)

-- Loads Package Files
RequireAllLuaFilesInFolder("Client/Config")

Package.Require("Exhibits.lua")
Package.Require("Texts.lua")
Package.Require("Effects.lua")
Package.Require("Halloween.lua")

-- Text shown in the escape menu, it replaces the Sandbox's one since the map loads after the game mode
Client.SetEscapeMenuText([[
<h1>Playground</>

A tour of what nanos world offers out of the box. Walk through the coloured doors to try weapons, vehicles, physics, the sandbox tools and every native entity.

<h2>Sandbox Controls</>
- <strong>Q:</> Spawn Menu, with props, entities, weapons, vehicles and tools
- <strong>C:</> Context Menu, to tweak your character and the world
- <strong>Z:</> Undo the last thing you spawned
- <strong>B:</> No Clip
- <strong>J:</> Ragdoll
- <strong>Tab:</> Scoreboard
]])

Package.Subscribe("Load", function()
	Playground.SpawnExhibits()
	Playground.SpawnTexts()
	Playground.SpawnFountain()
end)

Package.Subscribe("Unload", function()
	for _, entity in ipairs(spawned) do
		if (entity and entity.IsValid and entity:IsValid()) then
			entity:Destroy()
		end
	end

	spawned = {}
end)
