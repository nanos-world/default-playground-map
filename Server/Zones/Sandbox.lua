-- Sandbox zone: each tool gun on its bench and each sandbox entity on its pedestal, when Sandbox runs

local ENTITY_LIFT = 20
local TOOL_REACH = 300                 -- a tool gun left further than this from its bench, by nobody holding it, goes back on it at the next refill
local BALLOON_LIFT = 100000
local BALLOON_SPREAD = 45              -- between the balloons' weights, across the pad
local BALLOON_CORD = 110               -- the shortest cord, the middle balloon's is 60 longer

local SKIP = {}

-- Tool guns lie on their side on their benches, the middle of the gun on the middle of the bench: per class, the centre of its mesh's bounds from its
-- pivot and its half thickness lying down (the bounds' Y, which a 90 roll turns upright); SK_ToolGun unless listed
local TOOL_SHAPES = {
	ToolGun = { centre = Vector(12.85, 0, 6.33), half = 4.5 },
	PhysicsGun = { centre = Vector(15.92, 0, 5.81), half = 8.04 },
	PukeGun = { centre = Vector(9.12, 0, 2.48), half = 3.07 },
}
-- The physics gun's pedestal shows two, side by side and pointing opposite ways, this far from its middle each
local PHYSICS_GUN_APART = 15

local function LyingTool(spot, name, yaw, offset)
	local shape = TOOL_SHAPES[name] or TOOL_SHAPES.ToolGun
	local rotation = Rotator(0, yaw, 90)
	return Playground.Top(spot, shape.half + 0.5) + (offset or Vector()) - rotation:RotateVector(shape.centre), rotation
end

-- Sandbox entities whose constructor does not take (location, rotation), as the tool guns spawn them
-- Entities shown as several copies, at these offsets on their pad
local COPIES = {
	-- A square pyramid (the melon is a 27 x 28 ball): 3 x 3 resting on the pedestal, 2 x 2 in the pockets between them, one on top
	Breakable = {},
}
local MELON_STEP = 27.5
local MELON_BASE_Z = -5.5
for layer, count in ipairs({ 3, 2, 1 }) do
	for i = 1, count do
		for j = 1, count do
			-- Each layer half a step in from the one under it, a pocket's depth higher (step / sqrt 2) plus a little air to settle into
			local x, y = (i - (count + 1) / 2) * MELON_STEP, (j - (count + 1) / 2) * MELON_STEP
			table.insert(COPIES.Breakable, Vector(x, y, MELON_BASE_Z + (layer - 1) * (MELON_STEP / math.sqrt(2) + 0.5)))
		end
	end
end

-- The breakable melons standing in the pyramid: it falls together, and is cleared a while after one breaks
local melon_pyramid = {}
local MELON_CLEAR = 8000

local CUSTOM_SPAWN = {
	-- Hangs from a small hook above the pedestal instead of from the world origin
	RopeLight = function(class, location)
		local hook = StaticMesh(location + Vector(0, 0, 160), Rotator(), "nanos-world::SM_Cube")
		hook:SetScale(Vector(0.3, 0.3, 0.05))
		local light = class(location + Vector(0, 0, 60), Vector(), Rotator(), Vector(0, 0, -1), hook)
		light:Subscribe("Destroy", function() if (hook:IsValid()) then hook:Destroy() end end)
		return light
	end,
	-- The pyramid breaks as one: the first melon hit splits and lets the rest tumble, so it is wired here and Sandbox's own breaking is kept off it
	-- Every melon has physics; the bottom layer has a strong angular damping, so the round melons slide instead of rolling apart under the ones on top
	Breakable = function(_, location, rotation, offset)
		-- Turned with the pyramid, so each melon lies along the row
		local melon = Prop(location, rotation + Rotator(0, 90, 0), "nanos-world::SM_Fruit_Watermelon_01", CollisionType.Normal, true)
		melon:SetValue("Unbreakable", true)
		melon_pyramid[#melon_pyramid + 1] = melon
		if (offset.Z == MELON_BASE_Z) then
			melon:SetPhysicsDamping(0.01, 50)
		end
		melon:Subscribe("TakeDamage", function(self)
			local at, yaw = self:GetLocation(), self:GetRotation().Yaw
			self:Destroy()
			for _, other in ipairs(melon_pyramid) do
				if (other:IsValid()) then other:SetPhysicsDamping(0.01, 0) end
			end
			-- A while later the rest goes too, so the next refill stacks a whole new pyramid
			local pyramid = melon_pyramid
			melon_pyramid = {}
			Timer.SetTimeout(function()
				for _, other in ipairs(pyramid) do
					if (other:IsValid() and not other:GetHandler()) then other:Destroy() end
				end
			end, MELON_CLEAR)
			for _, side in ipairs({ -1, 1 }) do
				-- Each half rolled so its cut faces the other one, split along the melon's own sideways axis
				local rotation = Rotator(0, yaw, -side * 90)
				local half = Prop(at + Rotator(0, yaw, 0):RotateVector(Vector(0, side * 10, 5)), rotation, "nanos-world::SM_Fruit_Watermelon_01_Half_01", CollisionType.Normal, true, GrabMode.Enabled)
				half:SetLifeSpan(10)
			end
		end)
		return melon
	end,
	-- The TV stays on the pedestal; its camera (a separate prop that would fall over) floats beside it, looking at the visitor
	CCTV = function(class, location, rotation)
		local tv = class(location, rotation)
		local camera = tv.camera
		if (camera and camera:IsValid()) then
			camera:SetGravityEnabled(false)
			camera:SetLocation(location + Vector(140, -30, 110))
			camera:SetRotation(Rotator(-10, rotation.Yaw - 180, 0))
		end
		return tv
	end,
	-- A bare 102 cm panel with no stand: upright on the pedestal with gravity off, or it falls flat
	PhotoFrame = function(class, location, rotation)
		local frame = class(location - Vector(0, 0, ENTITY_LIFT - 1), rotation)
		frame:SetGravityEnabled(false)
		return frame
	end,
	-- Standing on its tail, shining straight up; gravity off, it is a narrow tube that would tip over
	Flashlight = function(class, location, rotation)
		local light = class(location - Vector(0, 0, ENTITY_LIFT - 1), Rotator(90, rotation.Yaw, 0))
		light:SetGravityEnabled(false)
		return light
	end,
	-- Upright and still: it is tall and narrow, with gravity it tips over
	Sign = function(class, location, rotation)
		local sign = class(location + Vector(0, 0, 12), rotation)
		sign:SetGravityEnabled(false)
		return sign
	end,
	-- Three balloons, each tied to its own weight on the pad: tied to one point they all float to the same spot above it and pop on each other (Balloon pops on
	-- any hit over 1000), so the weights stand apart and the cords differ in length, and each balloon spawns right where its cord holds it
	-- If any of them pops, the set goes, weights included, so the slot (which follows the first) brings back all three instead of leaving two untethered
	Balloon = function(class, location, rotation)
		local weights, balloons = {}, {}
		local across = Rotator(0, rotation.Yaw, 0):GetRightVector()
		for i = 1, 3 do
			local at = location + across * ((i - 2) * BALLOON_SPREAD)
			local weight = StaticMesh(at, Rotator(), "nanos-world::SM_Cube")
			weight:SetScale(Vector(0.2, 0.2, 0.12))
			weights[i] = weight
			-- Balloon spawns 50 along the direction from the location it is given
			local length = BALLOON_CORD + (i % 2) * 60
			local balloon = class(at + Vector(0, 0, length - 50), Rotator(), nil, nil, nil, Vector(), Rotator(), Vector(0, 0, 1), weight, BALLOON_LIFT, length, "nanos-world::SM_Balloon_0" .. i)
			balloons[i] = balloon
			Playground.Track(balloon)
		end
		local gone = false
		for _, balloon in ipairs(balloons) do
			balloon:Subscribe("Destroy", function()
				-- Once: each Destroy below fires this again
				if (gone) then return end
				gone = true
				for _, other in ipairs(balloons) do
					if (other ~= balloon and other:IsValid()) then other:Destroy() end
				end
				for _, weight in ipairs(weights) do
					if (weight:IsValid()) then weight:Destroy() end
				end
			end)
		end
		return balloons[1]
	end,
}

Playground.Setup("Sandbox", function()
	if (not Playground.HasSandbox()) then
		Console.Log("Playground: Sandbox not loaded, the tool benches stay empty")
		return
	end

	for _, entry in ipairs(Playground.SpotsWith("Sandbox_Tool_")) do
		local name = entry.name:sub(#"Sandbox_Tool_" + 1)
		local class = Playground.FindClass(name)

		if (class and name == "PhysicsGun") then
			-- Two on the pedestal, side by side across it, one pointing each way
			local yaw = Playground.FrontYaw(entry.spot) + 90
			local across = Rotator(0, yaw, 0):GetRightVector()
			for _, side in ipairs({ -1, 1 }) do
				local location, rotation = LyingTool(entry.spot, name, yaw + (side > 0 and 180 or 0), across * side * PHYSICS_GUN_APART)
				Playground.Slot(function() return class(location, rotation) end, TOOL_REACH)
			end
		elseif (class) then
			-- Lying on its side along the bench, muzzle to the visitor's left, centred on it
			local location, rotation = LyingTool(entry.spot, name, Playground.FrontYaw(entry.spot) + 90)
			Playground.Slot(function() return class(location, rotation) end, TOOL_REACH)
		else
			Console.Warn("Playground: sandbox tool '%s' not found", name)
		end
	end

	for _, entry in ipairs(Playground.SpotsWith("Sandbox_Ent_")) do
		local name = entry.name:sub(#"Sandbox_Ent_" + 1)
		local class, custom = Playground.FindClass(name), CUSTOM_SPAWN[name]

		if (SKIP[name]) then
			-- Nothing to show
		elseif (class or custom) then
			-- Flat pads put the entity right on the floor, pedestals give it a little air
			local location = Playground.Top(entry.spot, (entry.spot.mesh == "Disc" or entry.spot.mesh == "Plinth") and 2 or ENTITY_LIFT)
			-- Spawned like the spawn menu does: rotation = the look direction of a visitor facing the pedestal (from -Y)
			local rotation = Rotator(0, entry.spot.rotation.Yaw + 90, 0)
			for _, offset in ipairs(COPIES[name] or { Vector() }) do
				local at = location + offset
				Playground.Slot(function() return custom and custom(class, at, rotation, offset) or class(at, rotation) end)
			end
		else
			Console.Warn("Playground: sandbox entity '%s' not found", name)
		end
	end
end)
