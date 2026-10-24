-- Soft dependency on the Sandbox game-mode
-- A map cannot require a game-mode, so nothing assumes Sandbox is loaded: whatever needs it (its entities, the buttons) is not spawned without it, no stand-ins
-- Sandbox's classes are registered globally (Prop.Inherit), so a fixed name is used as the global itself; a name read from a spot label goes through FindClass

function Playground.HasSandbox()
	return Sandbox ~= nil
end

-- Finds a registered class by name among everything inheriting from any of the parents
function Playground.FindClass(name, parents)
	for _, parent in ipairs(parents or { Weapon, Prop, StaticMesh, Melee }) do
		for _, class in pairs(parent.GetInheritedClasses(true)) do
			if (class.GetName() == name) then
				return class
			end
		end
	end

	return nil
end
