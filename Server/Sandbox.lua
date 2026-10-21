-- Soft dependency on the Sandbox game-mode
--
-- A map cannot require a game-mode, so nothing assumes Sandbox is loaded. Its classes are looked up
-- by name through the class registry, and whatever needs Sandbox (its entities, the buttons) is not spawned without it: no stand-ins

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
