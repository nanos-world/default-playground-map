-- Playground map, client side: what only the clients spawn (exhibits of client-only classes, texts, sounds) and the Halloween sky

-- Everything the client spawned, so a reload leaves nothing behind
local spawned = {}

function Playground.Keep(entity)
	spawned[#spawned + 1] = entity

	return entity
end

-- Loads Package Files
RequireAllLuaFilesInFolder("Client/Config")

Package.Require("Exhibits.lua")
Package.Require("Texts.lua")
Package.Require("Effects.lua")
Package.Require("Halloween.lua")

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
