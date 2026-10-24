-- Sandbox & physics toys: prop yard pads and loose props, a bed car with a thruster, crate pyramid, the joints & cables yard (pendulum, elastics, tire swing,
-- seesaw, chain, punching bag, speed bag), trampoline, pressure plate farm gate, lever door, ball drop, rocket potty, wired rope lights, fruit cannon and box wall,
-- lookout tower lift and fireworks
-- The toys a button drives (Sandbox's LogicButton) only spawn when Sandbox runs

local CUBE = "nanos-world::SM_Cube"
local CRATE = "nanos-world::SM_Crate_07"
local LOOSE_REACH = 3000

-- A loose physics prop that comes back when it is destroyed or carried far away
local function Loose(location, rotation, asset, scale)
	return Playground.Slot(function()
		local prop = Prop(location, rotation, asset, CollisionType.Normal, true, GrabMode.Enabled)
		if (scale) then prop:SetScale(scale) end
		return prop
	end, LOOSE_REACH)
end

-- Fixed helper geometry the package needs (anchors, doors, hooks), never respawned
local function Fixed(location, rotation, asset, scale)
	local mesh = Playground.Track(StaticMesh(location, rotation, asset))
	if (scale) then mesh:SetScale(scale) end
	return mesh
end

-- A control on top of a button pedestal spot (Playground.Button)
local function Switch(spot, label_on, label_off, on_activate, on_deactivate, switchable, kind, cooldown)
	return Playground.Button(spot.location + Vector(0, 0, spot.top), Rotator(0, spot.rotation.Yaw, 0), label_on, label_off, on_activate, on_deactivate, switchable, kind, nil, nil, cooldown)
end

-- A sliding door at a door spot (SM_Cube is centred, the spot sits at the door's base); returns a function that opens or closes it
local DOOR_RISE = 310

local function SlidingDoor(spot)
	-- Up to the lintel's underside (sandbox.py door_frame: 320 above the ground, the spot on the grass at 5)
	local closed = spot.location + Vector(0, 0, 157.5)
	local door = Fixed(closed, spot.rotation, CUBE, Vector(0.2, 3.4, 3.15))
	door:SetMaterialColorParameter("Tint", Color(0.9, 0.35, 0.05))

	local is_open = false
	return function(open)
		if (open == is_open) then return end
		is_open = open
		door:TranslateTo(closed + Vector(0, 0, open and DOOR_RISE or 0), 1.2)
		Playground.PlaySound(closed, "nanos-world::A_Switch_Button_01")
	end
end

-- What each pad on the boulevard between the tool rows carries: asset, x, y in the pad's axes, lift above its top (the pivot's height), scale, yaw, roll
local TOOL_PADS = {
	{
		{ "nanos-world::SM_Cube_VR_02", -80, -30, 30, 0.6, 15 },
		{ "nanos-world::SM_Cube_VR_01", 30, 55, 26, 1, 40 },
		{ "nanos-world::SM_Cube_VR_03", 95, -45, 61, 0.6, 0 },
		{ "nanos-world::SM_Ball_VR", -10, -50, 26, 0.35 },
		{ "nanos-world::SM_Pyramid_VR", -95, 60, 21, 0.5, 30 },
	},
	{
		{ "nanos-world::SM_WoodenTable", 0, 0, 1 },
		{ "nanos-world::SM_WoodenChair", -105, 0, 1, 1, -90 },
		{ "nanos-world::SM_WoodenChair", 105, 0, 1, 1, 90 },
		{ "nanos-world::SM_Toolbox_01", -20, 10, 88, 1, 20 },
		{ "nanos-world::SM_Fruit_Watermelon_01", 35, -15, 88 },
	},
	{
		{ "nanos-world::SM_Crate_07", -80, -35, 1 },
		{ "nanos-world::SM_Crate_03", -80, -35, 57, 1, 20 },
		{ "nanos-world::SM_Barrel_02", 35, -50, 1 },
		{ "nanos-world::SM_OilDrum", 95, 40, 1 },
		{ "nanos-world::SM_Bucket5Gallon", -10, 55, 1 },
	},
	{
		{ "nanos-world::SM_BarrelTub", -85, 0, 1 },
		{ "nanos-world::SM_Offroad_Tire", 35, -40, 21, 1, 0, 90 },
		{ "nanos-world::SM_Cone", 105, 55, 26, 0.5 },
		{ "nanos-world::SM_Basket_01", 15, 60, 1 },
		{ "nanos-world::SM_KidsBall", -85, 0, 52 },
	},
}

-- Loose props scattered on the plaza beside the physics gun, dealt from a shuffled deck so they rarely repeat
-- asset, lift (its pivot's height when standing), scale, yaw, roll
local SCATTER_PROPS = {
	{ "nanos-world::SM_Crate_07", 1 },
	{ "nanos-world::SM_Crate_03", 1 },
	{ "nanos-world::SM_Crate_04", 1 },
	{ "nanos-world::SM_Barrel_02", 1 },
	{ "nanos-world::SM_OilDrum", 1 },
	{ "nanos-world::SM_PlasticBarrel_01", 1 },
	{ "nanos-world::SM_BarrelTub", 1 },
	{ "nanos-world::SM_Bucket5Gallon", 1 },
	{ "nanos-world::SM_Basket_01", 1 },
	{ "nanos-world::SM_Toolbox_01", 1 },
	{ "nanos-world::SM_WoodenChair", 1 },
	{ "nanos-world::SM_RockingChair", 3 },
	{ "nanos-world::SM_Stool", 1 },
	{ "nanos-world::SM_CoffeeTable", 1 },
	{ "nanos-world::SM_Cube_VR_01", 26 },
	{ "nanos-world::SM_Cube_VR_02", 30, 0.6 },
	{ "nanos-world::SM_Pyramid_VR", 24, 0.6 },
	{ "nanos-world::SM_Ball_VR", 26, 0.35 },
	{ "nanos-world::SM_Cone", 26, 0.5 },
	{ "nanos-world::SM_Offroad_Tire", 21, 1, 0, 90 },
	{ "nanos-world::SM_KidsBall", 1 },
	{ "nanos-world::SM_Fruit_Watermelon_01", 1 },
}
-- Pumpkins are kept for Halloween
if (Playground.theme == "halloween") then table.insert(SCATTER_PROPS, { "nanos-world::SM_Fruit_Pumpkin_01", 1 }) end
local deck = {}

local function DealProp()
	if (#deck == 0) then
		for i, item in ipairs(SCATTER_PROPS) do deck[i] = item end
		for i = #deck, 2, -1 do
			local j = math.random(i)
			deck[i], deck[j] = deck[j], deck[i]
		end
	end
	return table.remove(deck)
end
-- One prop per cell of this size, nudged inside it and turned at random, some cells left empty
local SCATTER_CELL = 120
local SCATTER_FILL = 0.75

-- A loose prop on a pad spot, at x, y in the pad's axes and lift above its top
local function LooseOn(spot, x, y, asset, lift, scale, yaw, roll)
	scale = scale or 1
	return Loose(Playground.At(spot, x, y, spot.top + lift), Rotator(0, spot.rotation.Yaw + (yaw or 0), roll or 0), asset, scale ~= 1 and Vector(scale, scale, scale) or nil)
end

-- Props strewn over a marker spot's area (its scale x 100 cm), standing on the ground at the marker; their slots go into out
local function Scatter(spot, out)
	local sx, sy = spot.scale.X * 100, spot.scale.Y * 100
	local nx, ny = math.max(1, math.floor(sx / SCATTER_CELL)), math.max(1, math.floor(sy / SCATTER_CELL))
	local ground = { location = spot.location, rotation = spot.rotation, top = 0 }
	for i = 1, nx do
		for j = 1, ny do
			if (math.random() < SCATTER_FILL) then
				local item = DealProp()
				local x = (i - (nx + 1) / 2) * sx / nx + math.random(-25, 25)
				local y = (j - (ny + 1) / 2) * sy / ny + math.random(-25, 25)
				out[#out + 1] = LooseOn(ground, x, y, item[1], item[2], item[3], (item[4] or 0) + math.random(0, 359), item[5])
			end
		end
	end
end

-- A car on the grass built like the sandbox does it: a bed for a chassis and four Wheel Gun wheels on cables, the wheels off until someone turns them on,
-- and a thruster on its back (off). Its button puts it back if it is not home, then fires the thruster for a moment, up the ramp ahead of it
local BED_HALF = Vector(95, 64, 40)    -- where the wheels go on SM_Bed's sides: half length, half width, height (unscaled)
local TIRE = "nanos-world::SM_Offroad_Tire"
-- Sandbox's WHEELS_CONFIG entry for the tire (that global is not exported to other packages)
local TIRE_CONFIG = { offset = Vector(0, -20, 0), direction = Vector(0, -1, 0) }
local BED_MASS = 100
local BED_THRUST = 700000
local BED_BURN = 2000
local BED_HOME = 150                   -- further than this from home it is put back before a launch
local BED_RESET = 8000                 -- ms after a launch it is put back home anyway

local function SpawnBedCar(spot, button_spot)
	local wheel_class = Playground.FindClass("Wheel", { Prop })
	if (not wheel_class) then return end
	local thruster_class = Playground.FindClass("Thruster", { Prop })
	-- The current car's thruster and wheels
	local thruster, wheels = nil, {}

	local slot = Playground.Slot(function()
		-- Not grabbable: picking it up tears the wheels off
		local bed = Prop(spot.location + Vector(0, 0, 45), Rotator(0, spot.rotation.Yaw, 0), "nanos-world::SM_Bed", CollisionType.Normal, true, GrabMode.Disabled)
		bed:SetMassOverride(BED_MASS)
		local config = TIRE_CONFIG
		local bed_quat = bed:GetRotation():Quaternion()
		local parts = {}
		wheels = {}

		for _, x in ipairs({ -BED_HALF.X, BED_HALF.X }) do
			for _, side in ipairs({ -1, 1 }) do
				-- WheelGun.OnSpawnWheel with the hit on the side face: its normal (±Y) sets the wheel's facing, the offset puts it beside the face
				local relative = Vector(x, side * BED_HALF.Y, BED_HALF.Z)
				local wheel_quat = bed_quat * Rotator(0, side * 90, 0):Quaternion() * config.direction:ToOrientationQuat()
				local hit = bed:GetLocation() + bed_quat:RotateVector(relative)
				local location = hit - wheel_quat:RotateVector(config.offset)
				-- Its config too: Activate reads the drive direction from it
				local wheel = wheel_class(location, wheel_quat:Rotator(), TIRE, 2000000, false, side < 0, nil, config)

				local cable = Cable(location, false)
				cable:SetPhysicsConstraintSettings(true)
				cable:SetAngularLimits(ConstraintMotion.Locked, ConstraintMotion.Locked, ConstraintMotion.Free)
				cable:AttachStartTo(wheel)
				cable:AttachEndTo(bed, relative, nil, bed_quat:UnrotateVector(location - hit))
				cable:SetVisibility(false)
				parts[#parts + 1] = Playground.Track(wheel)
				parts[#parts + 1] = Playground.Track(cable)
				wheels[#wheels + 1] = wheel
			end
		end

		-- The thruster on its back, pushing it forwards (its force is along its own X)
		if (thruster_class) then
			thruster = Playground.Track(thruster_class(bed:GetLocation(), Rotator(), nil, nil, BED_THRUST, false))
			thruster:AttachTo(bed, AttachmentRule.SnapToTarget, "", 1)
			thruster:SetRelativeLocation(Vector(-BED_HALF.X - 20, 0, 50))
			thruster:SetRelativeRotation(Rotator())
			parts[#parts + 1] = thruster
		end

		-- The car comes and goes as one
		bed:Subscribe("Destroy", function()
			for _, part in ipairs(parts) do
				if (part:IsValid()) then part:Destroy() end
			end
		end)
		return bed
	end, 3000)

	if (not slot or not button_spot or not thruster_class) then return end

	local burn_timer, reset_timer = nil, nil
	Switch(button_spot, "launch", "launch", function()
		local bed = slot.entity
		if (not bed or not bed:IsValid() or bed:GetLocation():Distance(slot.home) > BED_HOME) then
			bed = Playground.Respawn(slot)
		end
		if (not thruster or not thruster:IsValid()) then
			Console.Warn("Playground: the bed car has no thruster to launch")
			return
		end
		Console.Log("Playground: bed car launched")
		-- The thruster pushes and the wheels drive while it burns
		local burning, driven = thruster, wheels
		burning:Activate()
		for _, wheel in ipairs(driven) do
			if (wheel:IsValid()) then wheel:Activate() end
		end
		if (burn_timer) then Timer.ClearTimeout(burn_timer) end
		burn_timer = Timer.SetTimeout(function()
			burn_timer = nil
			if (burning:IsValid()) then burning:Deactivate() end
			for _, wheel in ipairs(driven) do
				if (wheel:IsValid()) then wheel:Deactivate() end
			end
		end, BED_BURN)
		if (reset_timer) then Timer.ClearTimeout(reset_timer) end
		reset_timer = Timer.SetTimeout(function()
			reset_timer = nil
			Playground.Respawn(slot)
		end, BED_RESET)
	end, nil, false, "PushButton", BED_BURN + 500)
end

-- Crate pyramid, 4 / 3 / 2 / 1 along the pad's X, to knock over with the physics gun
local CRATE_SIZE = 60

local function SpawnPyramid(spot, out)
	for layer = 0, 3 do
		local count = 4 - layer
		for i = 0, count - 1 do
			local along = (i - (count - 1) / 2) * (CRATE_SIZE + 2)
			out[#out + 1] = Loose(Playground.At(spot, along, 0, spot.top + 1 + layer * CRATE_SIZE), Rotator(0, spot.rotation.Yaw, 0), CRATE)
		end
	end
end

-- A small dark hook bolted under a beam, its top at point (the beam's underside); cables start at its bottom so they visibly hang from the beam
local HOOK = 8

local function Hook(point)
	local hook = Fixed(point - Vector(0, 0, HOOK / 2), Rotator(), CUBE, Vector(HOOK, HOOK, HOOK) / 100)
	hook:SetMaterialColorParameter("Tint", Color(0.03, 0.03, 0.03))
	return hook
end

-- Pendulum: ball hanging from the beam on a limited cable, spawned at rest straight under its hook
local PENDULUM_LENGTH = 330

local function SpawnPendulum(spot, beam_spot)
	-- Under the beam (its marker at the beam's underside, sandbox.py JOINT_TOYS)
	local top = beam_spot.location
	local anchor = Hook(top)

	-- Its middle a radius under the cable's full length below the hook's bottom (SM_Ball_VR radius 70 at 0.6)
	local ball = Playground.Track(Prop(top - Vector(0, 0, HOOK + PENDULUM_LENGTH + 70 * 0.6), Rotator(), "nanos-world::SM_Ball_VR", CollisionType.Normal, true, GrabMode.Enabled))
	ball:SetScale(Vector(0.6, 0.6, 0.6))

	local cable = Playground.Track(Cable(top, true))
	cable:SetLinearLimits(ConstraintMotion.Limited, ConstraintMotion.Limited, ConstraintMotion.Limited, PENDULUM_LENGTH, 0, true, 10000, 100)
	-- Rendered shorter than the limit, so it is drawn taut instead of sagging between its ends
	cable:SetCableSettings(PENDULUM_LENGTH * 0.5, 10, 2)
	cable:SetRenderingSettings(4, 4, 1)
	cable:AttachStartTo(anchor, Vector(0, 0, -50))
	-- On the ball's surface (SM_Ball_VR radius 70): the offset is in the ball's unscaled space, the 0.6 scale brings it to the scaled surface
	cable:AttachEndTo(ball, Vector(0, 0, 70))
end

-- A cable from a hook under a beam at from to a point on an entity (in its unscaled space), drawn taut
-- limit: its length; soft: springy (stiffness, damping) instead of rigid
local function Tie(from, entity, relative, limit, soft, stiffness, damping, width)
	local cable = Playground.Track(Cable(from, true))
	cable:AttachStartTo(Hook(from), Vector(0, 0, -50))
	cable:SetLinearLimits(ConstraintMotion.Limited, ConstraintMotion.Limited, ConstraintMotion.Limited, limit, soft and 0.5 or 0, soft or false, stiffness or 0, damping or 0)
	cable:SetCableSettings(limit * 0.6, 8, 2)
	cable:SetRenderingSettings(width or 3, 4, 1)
	cable:AttachEndTo(entity, relative)
	return cable
end

-- The same between two entities
local function TieTo(a, a_relative, b, b_relative, limit, soft, stiffness, damping)
	local cable = Playground.Track(Cable(a:GetLocation(), true))
	cable:SetLinearLimits(ConstraintMotion.Limited, ConstraintMotion.Limited, ConstraintMotion.Limited, limit, 0.25, soft or false, stiffness or 0, damping or 0)
	cable:SetCableSettings(limit * 0.6, 8, 2)
	cable:SetRenderingSettings(3, 4, 1)
	cable:AttachStartTo(a, a_relative)
	cable:AttachEndTo(b, b_relative)
	return cable
end

local function Shape(location, rotation, asset, scale, tint, grab)
	local prop = Playground.Track(Prop(location, rotation or Rotator(), asset, CollisionType.Normal, true, grab or GrabMode.Enabled))
	if (scale) then prop:SetScale(scale) end
	if (tint) then prop:SetMaterialColorParameter("Tint", tint) end
	return prop
end

-- Elastics: bouncy balls on long, soft elastics under one beam (along its marker's Y), each longer than the last; pull one down or jump into it. The
-- elastics look like the Elastic Gun's, tinted like their ball
local ELASTICS = {
	{ -130, 110, Color(0.9, 0.35, 0.05) },
	{ 0, 140, Color(0.95, 0.8, 0.1) },
	{ 130, 170, Color(0.1, 0.55, 0.9) },
}
local ELASTIC_SCALE = 0.5              -- SM_Sphere radius 50
local ELASTIC_STIFFNESS = 12
local ELASTIC_DAMPING = 0.05

local function SpawnElastics(spot)
	for _, elastic in ipairs(ELASTICS) do
		local top = Playground.At(spot, 0, elastic[1], 0)
		local ball = Shape(top - Vector(0, 0, elastic[2] + 50 * ELASTIC_SCALE), Rotator(), "nanos-world::SM_Sphere", Vector(ELASTIC_SCALE, ELASTIC_SCALE, ELASTIC_SCALE), elastic[3])
		ball:SetMaterialScalarParameter("Roughness", 0)
		ball:SetMaterialColorParameter("Tint", elastic[3])
		ball:SetPhysicalMaterial("nanos-world::PM_RubberBouncy")
		ball:SetMassOverride(10)
		ball:SetPhysicsDamping(0, 0)
		local cable = Tie(top, ball, Vector(0, 0, 50), elastic[2], true, ELASTIC_STIFFNESS, ELASTIC_DAMPING, 4)
		cable:SetMaterial("nanos-world::M_Default_Masked_Lit")
		cable:SetMaterialColorParameter("Tint", elastic[3])
	end
end

-- Tire swing: a big tyre lying flat, hung by three ropes from one hook on the beam; stand or sit on it and push off
local SWING_SCALE = 1.4                -- SM_Offroad_Tire: radius 51, 20 thick each side of its middle (along its Y, which a 90 roll stands up)
local SWING_HEIGHT = 70                -- its middle above the ground

local function SpawnTireSwing(spot)
	local hook = spot.location
	local centre = Vector(hook.X, hook.Y, SWING_HEIGHT)
	local tire = Shape(centre, Rotator(0, 0, 90), "nanos-world::SM_Offroad_Tire", Vector(SWING_SCALE, SWING_SCALE, SWING_SCALE))
	for k = 0, 2 do
		local a = math.rad(k * 120)
		-- On top of the tread: the tyre's local X/Z is its round face, its local -Y the top once rolled up
		local relative = Vector(math.cos(a) * 42, -20, math.sin(a) * 42)
		local at = tire:GetLocation() + tire:GetRotation():RotateVector(relative * SWING_SCALE)
		Tie(hook, tire, relative, hook:Distance(at), false, 0, 0, 3)
	end
end

-- Seesaw: a plank along the marker's X on a hinge at its middle: two rigid ball joints on the plank's underside, either side of its middle on one line across it
local PLANK = Vector(380, 45, 8)
local PLANK_TINT = Color(0.9, 0.35, 0.05)

local function SpawnSeesaw(spot)
	local middle = spot.location + Vector(0, 0, PLANK.Z / 2)
	local plank = Shape(middle, Rotator(0, spot.rotation.Yaw, 0), CUBE, PLANK / 100, PLANK_TINT, GrabMode.Disabled)
	plank:SetMassOverride(15)
	plank:SetPhysicsDamping(0, 0.05)
	for _, side in ipairs({ -1, 1 }) do
		local hinge = Playground.At(spot, 0, side * PLANK.Y / 2, 0)
		local cable = Playground.Track(Cable(hinge, false))
		cable:SetLinearLimits(ConstraintMotion.Locked, ConstraintMotion.Locked, ConstraintMotion.Locked)
		cable:SetAngularLimits(ConstraintMotion.Free, ConstraintMotion.Free, ConstraintMotion.Free)
		-- SM_Cube's underside middle at the side's edge, in its unscaled space
		cable:AttachEndTo(plank, Vector(0, side * 50, -50))
	end
end

-- Chain: cubes hanging one under the other, each roped to the one above, the first to the beam
local CHAIN_LINKS = 4
local CHAIN_CUBE = 40
local CHAIN_GAP = 30
local CHAIN_TINTS = { Color(0.9, 0.35, 0.05), Color(0.95, 0.8, 0.1), Color(0.1, 0.55, 0.9), Color(0.85, 0.15, 0.45) }

local function SpawnChain(spot)
	local above, above_relative = nil, nil
	local z = spot.location.Z - 2
	for i = 1, CHAIN_LINKS do
		z = z - CHAIN_GAP - CHAIN_CUBE / 2
		local cube = Shape(Vector(spot.location.X, spot.location.Y, z), Rotator(), CUBE, Vector(CHAIN_CUBE, CHAIN_CUBE, CHAIN_CUBE) / 100, CHAIN_TINTS[(i - 1) % #CHAIN_TINTS + 1])
		if (above) then
			TieTo(above, above_relative, cube, Vector(0, 0, 50), CHAIN_GAP, true, 1000, 10)
		else
			Tie(spot.location, cube, Vector(0, 0, 50), CHAIN_GAP, true, 1000, 10)
		end
		above, above_relative = cube, Vector(0, 0, -50)
		z = z - CHAIN_CUBE / 2
	end
end

-- Punching bag: a heavy cylinder on a short rigid hanger, free to swing and turn like a ball joint
local BAG = Vector(34, 34, 75)
local BAG_HANGER = 20

local function SpawnPunchBag(spot)
	local top = spot.location - Vector(0, 0, HOOK)
	local bag = Shape(top - Vector(0, 0, BAG_HANGER + BAG.Z / 2), Rotator(), "nanos-world::SM_Cylinder", BAG / 100, Color(0.55, 0.05, 0.04), GrabMode.Disabled)
	bag:SetMassOverride(30)
	local cable = Playground.Track(Cable(top, true))
	cable:AttachStartTo(Hook(spot.location), Vector(0, 0, -50))
	cable:SetLinearLimits(ConstraintMotion.Locked, ConstraintMotion.Locked, ConstraintMotion.Locked)
	cable:SetAngularLimits(ConstraintMotion.Free, ConstraintMotion.Free, ConstraintMotion.Free)
	cable:SetCableSettings(BAG_HANGER, 2, 1)
	cable:SetRenderingSettings(3, 4, 1)
	cable:AttachEndTo(bag, Vector(0, 0, 50), nil, Vector(0, 0, BAG_HANGER / BAG.Z * 100))
end

-- Speed bag: a small teardrop-ish bag on a very short hanger at head height, quick to swing back
local SPEED_BAG = Vector(26, 26, 34)
local SPEED_BAG_HANGER = 40            -- long enough to bring it down to face height under the 200 beam

local function SpawnSpeedBag(spot)
	local top = spot.location - Vector(0, 0, HOOK)
	local bag = Shape(top - Vector(0, 0, SPEED_BAG_HANGER + SPEED_BAG.Z / 2), Rotator(), "nanos-world::SM_Sphere", SPEED_BAG / 100, Color(0.6, 0.08, 0.05), GrabMode.Disabled)
	bag:SetMassOverride(3)
	local cable = Playground.Track(Cable(top, true))
	cable:AttachStartTo(Hook(spot.location), Vector(0, 0, -50))
	cable:SetLinearLimits(ConstraintMotion.Locked, ConstraintMotion.Locked, ConstraintMotion.Locked)
	cable:SetAngularLimits(ConstraintMotion.Free, ConstraintMotion.Free, ConstraintMotion.Free)
	cable:SetCableSettings(SPEED_BAG_HANGER, 2, 1)
	cable:SetRenderingSettings(2, 4, 1)
	cable:AttachEndTo(bag, Vector(0, 0, 50), nil, Vector(0, 0, SPEED_BAG_HANGER / SPEED_BAG.Z * 100))
end

-- Trampoline: anything that lands on the mat is thrown back up
local TRAMPOLINE_TOP = 43
local TRAMPOLINE_LAUNCH = 850

local function SpawnTrampoline(spot)
	-- Server triggers only test each actor's origin, which for a character is its capsule centre about 90 above its feet: tall enough to catch that, low enough for props on the mat
	local trigger = Playground.Track(Trigger(spot.location + Vector(0, 0, TRAMPOLINE_TOP + 70), Rotator(), Vector(180, 180, 70), TriggerType.Box, false, Color.WHITE, { "Character", "CharacterSimple", "Prop" }))

	trigger:Subscribe("BeginOverlap", function(self, entity)
		if (entity:IsA(Character) or entity:IsA(CharacterSimple)) then
			-- Walking movement eats an upward impulse, so a grounded character jumps with the launch speed instead (the impulse covers one landing from the air)
			local jump = entity:GetJumpZVelocity()
			entity:SetJumpZVelocity(TRAMPOLINE_LAUNCH)
			entity:Jump()
			entity:AddImpulse(Vector(0, 0, TRAMPOLINE_LAUNCH), true)
			Timer.SetTimeout(function() if (entity:IsValid()) then entity:SetJumpZVelocity(jump) end end, 500)
		elseif (entity:IsA(Prop)) then
			entity:AddImpulse(Vector(0, 0, TRAMPOLINE_LAUNCH), true)
		else
			return
		end

		Playground.PlaySound(spot.location + Vector(0, 0, TRAMPOLINE_TOP), "nanos-world::A_WoodSpring")
	end)
end

-- Farm gate at a door spot: two leaves of rails hinged on the frame's jambs, swinging open away from the spot's -X side (where its plate is) and back;
-- returns a function that opens or closes it. Each leaf is a set of bars attached to an invisible hinge, which turns
local GATE_HALF = 170                  -- a leaf's length, hinge to middle (sandbox.py door_frame: 340 between the jambs)
local GATE_RAILS = { 40, 110, 180, 250 }
local GATE_TINT = Color(0.9, 0.35, 0.05)
local GATE_SWING = 1.0

local function FarmGate(spot)
	local yaw = spot.rotation.Yaw
	local hinges = {}
	for _, side in ipairs({ -1, 1 }) do
		local hinge = Fixed(Playground.At(spot, 0, side * GATE_HALF, 0), Rotator(0, yaw, 0), "nanos-world::SM_None")
		-- Bars by their centre along the leaf (from the gate's middle, outwards) and height, size and roll
		local bars = {}
		for _, z in ipairs(GATE_RAILS) do bars[#bars + 1] = { GATE_HALF / 2, z, Vector(8, GATE_HALF - 4, 10), 0 } end
		bars[#bars + 1] = { GATE_HALF - 6, 145, Vector(10, 10, 240), 0 }
		bars[#bars + 1] = { 6, 145, Vector(10, 10, 240), 0 }
		-- The brace, from the hinge's foot up to the middle's top
		local rise, run = GATE_RAILS[#GATE_RAILS] - GATE_RAILS[1], GATE_HALF - 12
		bars[#bars + 1] = { GATE_HALF / 2, 145, Vector(6, math.sqrt(rise * rise + run * run), 8), side * math.deg(math.atan(rise, run)) }
		for _, bar in ipairs(bars) do
			local mesh = Fixed(Playground.At(spot, 0, side * bar[1], bar[2]), Rotator(0, yaw, bar[4]), CUBE, bar[3] / 100)
			mesh:SetMaterialColorParameter("Tint", GATE_TINT)
			mesh:AttachTo(hinge, AttachmentRule.KeepWorld, "", 0)
		end
		hinges[side] = hinge
	end

	local is_open = false
	return function(open)
		if (open == is_open) then return end
		is_open = open
		for side, hinge in pairs(hinges) do
			hinge:RotateTo(Rotator(0, yaw + (open and side * 90 or 0), 0), GATE_SWING)
		end
		Playground.PlaySound(spot.location, "nanos-world::A_Switch_Button_01")
	end
end

-- Pressure plate: the gate stays open while any character stands on the plate, and closes a moment after the last one steps off
local PLATE_CLOSE_DELAY = 1500

local function SpawnPlateDoor(plate_spot, door_spot)
	local set_open = FarmGate(door_spot)
	local radius = 100 * plate_spot.scale.X
	local trigger = Playground.Track(Trigger(plate_spot.location + Vector(0, 0, 60), Rotator(), Vector(radius, radius, 60), TriggerType.Box, false, Color.GREEN, { "Character", "CharacterSimple" }))

	local on_plate, close_timer = 0, nil
	trigger:Subscribe("BeginOverlap", function()
		on_plate = on_plate + 1
		if (close_timer) then Timer.ClearTimeout(close_timer) close_timer = nil end
		set_open(true)
	end)
	trigger:Subscribe("EndOverlap", function()
		on_plate = math.max(0, on_plate - 1)
		if (on_plate > 0) then return end
		close_timer = Timer.SetTimeout(function()
			close_timer = nil
			if (on_plate == 0) then set_open(false) end
		end, PLATE_CLOSE_DELAY)
	end)
end

-- Button door: the button slides the door up and lights the lamp, pressing again closes it
local function SpawnLogic(button_spot, door_spot, lamp_spot)
	local set_open = SlidingDoor(door_spot)

	-- The lamp spot is a marker on the lintel's front, its local +Y pointing away from the door
	local lamp = Fixed(lamp_spot.location, Rotator(), "nanos-world::SM_Sphere", Vector(0.3, 0.3, 0.3))
	local light = Playground.Track(Light(Playground.At(lamp_spot, 0, 40, 0), Rotator(), Color(1, 0.75, 0.3), LightType.Point, 30, 900))
	light:SetVisibility(false)

	local function Set(open)
		set_open(open)
		light:SetVisibility(open)
		lamp:SetMaterialColorParameter("Emissive", open and Color(10, 7, 2) or Color.BLACK)
	end

	Switch(button_spot, "open", "close", function() Set(true) end, function() Set(false) end, true, "Lever")
end

-- Ball drop: every press rains a load of bouncy balls from the chute's ring onto the pad; they vanish after a while
local BALL_DROP_HEIGHT = 650
local BALL_DROP_COUNT = 15
local BALL_LIFESPAN = 25

local function SpawnBallDrop(pad_spot, button_spot)
	local class = Playground.FindClass("BouncyBall", { Prop })
	if (not class) then return end

	local function Drop()
		for i = 1, BALL_DROP_COUNT do
			Timer.SetTimeout(function()
				-- Sandbox's own ball picks its random size and color, and keeps to the server's max_bouncy_balls like the spawn menu
				if (Sandbox.IsUnderSpawnLimit and not Sandbox.IsUnderSpawnLimit("BouncyBall")) then return end
				local location = pad_spot.location + Vector(math.random(-110, 110), math.random(-110, 110), BALL_DROP_HEIGHT)
				class(location, Rotator()):SetLifeSpan(BALL_LIFESPAN)
			end, i * 80)
		end
	end

	Switch(button_spot, "drop balls", "drop balls", Drop, nil, false, "PushButton")
end

-- Rocket potty: a portable toilet on the pad with a sandbox thruster on each side, wired to a sandbox button. Each press puts it back on the pad if it flew off,
-- then fires them for a moment. The thrusters only show it (flame and sound, next to no force): the lift is one force straight up on the potty itself, which
-- acts through its middle, so it rises straight instead of tipping over whichever way its weight leans
local ROCKET = "nanos-world::SM_Portapotty"
local ROCKET_DOOR = "nanos-world::SM_Portapotty_Door"
local ROCKET_DOOR_AT = Vector(58, 31, 0)   -- the door's hinge in its doorway on the potty's +X face
local ROCKET_FORCE = 150000
local ROCKET_BURN = 3000
local ROCKET_MASS = 50
local ROCKET_SIDE = 74                 -- booster distance from the middle: SM_Portapotty is 57 to its side, the thruster 16 thick at scale 0.5
local ROCKET_BOOSTER_Z = 110           -- about its middle's height
local ROCKET_STEADY = 4                -- angular damping, against any spin a bump starts
local ROCKET_BOOM_HEIGHT = 2500        -- above the pad it blows up (no damage) like a grenade
local ROCKET_RESPAWN = 3000            -- ms after that a fresh one stands on the pad
local ROCKET_WATCH = 150               -- ms between height checks while it flies

local function SpawnRocket(pad_spot, button_spot)
	local thruster_class = Playground.FindClass("Thruster", { Prop })
	if (not thruster_class) then return end

	local home = pad_spot.location + Vector(0, 0, pad_spot.top + 1)
	-- Its door towards the button
	local facing = Rotator(0, (button_spot.location - home):ToOrientationRotator().Yaw, 0)
	local button = Switch(button_spot, "launch", "launch", function() end, nil, false)
	local potty, thrusters, burn_timer

	-- A fresh potty, its door and its thrusters on the pad, wired to the button (the wire is what fires them when the button activates)
	local function Build()
		if (potty and potty:IsValid()) then potty:Destroy() end
		potty = Playground.Track(Prop(home, facing, ROCKET, CollisionType.Normal, true, GrabMode.Enabled))
		potty:SetMassOverride(ROCKET_MASS)
		potty:SetPhysicsDamping(0, ROCKET_STEADY)
		local door = StaticMesh(home, facing, ROCKET_DOOR)
		door:AttachTo(potty, AttachmentRule.SnapToTarget, "", 0)
		door:SetRelativeLocation(ROCKET_DOOR_AT)
		-- One booster on each side, clear of the ground: its force points along its X, pitched up so it pushes the potty upwards
		button:UnlinkAllEntities()
		thrusters = {}
		for _, side in ipairs({ -1, 1 }) do
			local thruster = Playground.Track(thruster_class(home, Rotator(), nil, nil, 1, false))
			thruster:AttachTo(potty, AttachmentRule.SnapToTarget, "", 1)
			thruster:SetRelativeLocation(Vector(0, side * ROCKET_SIDE, ROCKET_BOOSTER_Z))
			thruster:SetRelativeRotation(Rotator(90, 0, 0))
			-- Wired without a visible cable: the potty flies off with it
			button:LinkEntity(thruster, false)
			thrusters[#thrusters + 1] = thruster
		end
	end

	Build()

	local watch_timer, respawn_timer = nil, nil

	-- High enough: a grenade's blast and bang where it is, the potty gone, a fresh one on the pad a moment later
	local function Boom()
		if (watch_timer) then Timer.ClearInterval(watch_timer) watch_timer = nil end
		if (not potty:IsValid()) then return end
		local location = potty:GetLocation()
		potty:Destroy()
		local grenade = Grenade(location, Rotator(), "nanos-world::SM_None", "nanos-world::P_Grenade_Special", "nanos-world::A_Explosion_Large", CollisionType.StaticOnly, false)
		grenade:SetDamage(0, 0, 0, 0, 1)
		grenade:Explode()
		Playground.PlaySound(location, "nanos-world::A_Explosion_Large", 12000, 1)
		respawn_timer = Timer.SetTimeout(function()
			respawn_timer = nil
			Build()
		end, ROCKET_RESPAWN)
	end

	button.Activate = function(self, ...)
		if (respawn_timer) then Timer.ClearTimeout(respawn_timer) respawn_timer = nil end
		if (not potty:IsValid() or potty:GetLocation():Distance(home) > 150) then Build() end
		LogicButton.Activate(self, ...)
		if (watch_timer) then Timer.ClearInterval(watch_timer) end
		watch_timer = Timer.SetInterval(function()
			if (not potty:IsValid()) then
				Timer.ClearInterval(watch_timer)
				watch_timer = nil
			elseif (potty:GetLocation().Z > home.Z + ROCKET_BOOM_HEIGHT) then
				Boom()
			end
		end, ROCKET_WATCH)
		local lifted = potty
		lifted:SetForce(Vector(0, 0, ROCKET_FORCE), false)
		if (burn_timer) then Timer.ClearTimeout(burn_timer) end
		burn_timer = Timer.SetTimeout(function()
			burn_timer = nil
			if (lifted:IsValid()) then lifted:SetForce(Vector(), false) end
			for _, thruster in ipairs(thrusters) do
				if (thruster:IsValid()) then thruster:Deactivate() end
			end
		end, ROCKET_BURN)
	end
end

-- Wired rope lights: sandbox rope lights hanging from the gantry beam, linked with visible wires to a sandbox button
local ROPE_LIGHTS_COUNT = 4
local ROPE_LIGHTS_SPAN = 600

local function SpawnRopeLights(beam_spot, button_spot)
	local class = Playground.FindClass("RopeLight", { Prop })
	if (not class) then return end

	local button = Switch(button_spot, "lights on", "lights off", function() end, function() end)

	for i = 1, ROPE_LIGHTS_COUNT do
		local at = beam_spot.location + Vector((i - (ROPE_LIGHTS_COUNT + 1) / 2) * ROPE_LIGHTS_SPAN / (ROPE_LIGHTS_COUNT - 1), 0, -20)
		local hook = Fixed(at, Rotator(), CUBE, Vector(0.1, 0.1, 0.05))
		local light = Playground.Track(class(at - Vector(0, 0, 100), Vector(), Rotator(), Vector(0, 0, -1), hook))
		light:Deactivate()
		button:LinkEntity(light, true, Color.BLACK)
	end
end

-- Fruit cannon: each press fires a load of fruit at once from the muzzle (playground_props.py FruitCannon: local (0, 100, 87), barrel pitched 15) at the box
-- wall, with a grenade's blast on the muzzle
-- Only the big ones that break apart (Sandbox's breakable props): they read from afar, knock the boxes over and burst
local CANNON_FRUITS = { "nanos-world::SM_Fruit_Watermelon_01", "nanos-world::SM_Fruit_Cantaloupe_01", "nanos-world::SM_Fruit_Squash_01" }
local CANNON_MUZZLE = Vector(0, 140, 87)
local CANNON_PITCH = 5                 -- lower than the barrel (15): at CANNON_SPEED the fruits reach the wall 10 m away low down
local CANNON_SPEED = 4000
local CANNON_LOAD = 10
local CANNON_SPREAD = 16                -- degrees sideways, CANNON_RISE up and down, and each fruit 15% faster or slower
local CANNON_RISE = 6
local CANNON_CLUSTER = 50              -- the fruits start scattered this far round the muzzle, so they do not spawn inside each other
local CANNON_COOLDOWN = 1500          -- the button's: it takes no press while the cannon reloads
local CANNON_BLAST_SCALE = 0.75
local FRUIT_LIFESPAN = 15

local function SpawnCannon(cannon_spot, button_spot)
	local muzzle = Playground.At(cannon_spot, CANNON_MUZZLE.X, CANNON_MUZZLE.Y, CANNON_MUZZLE.Z)
	local yaw = Playground.FrontYaw(cannon_spot)
	local forward = Rotator(CANNON_PITCH, yaw, 0):GetForwardVector()
	local function Fire()
		local blast = Playground.Track(Particle(muzzle, Rotator(CANNON_PITCH, yaw, 0), "nanos-world::P_Explosion", true, true))
		blast:SetScale(Vector(CANNON_BLAST_SCALE, CANNON_BLAST_SCALE, CANNON_BLAST_SCALE))
		Playground.PlaySound(muzzle, "nanos-world::A_Explosion_Large", 4000)
		for _ = 1, CANNON_LOAD do
			local spread = function(range) return (math.random() * 2 - 1) * range end
			local direction = Rotator(CANNON_PITCH + spread(CANNON_RISE), yaw + spread(CANNON_SPREAD), 0):GetForwardVector()
			local offset = Vector(math.random() * 2 - 1, math.random() * 2 - 1, math.random() * 2 - 1) * CANNON_CLUSTER
			local fruit = Prop(muzzle + forward * CANNON_CLUSTER + offset, Rotator(math.random(0, 359), math.random(0, 359), 0), CANNON_FRUITS[math.random(#CANNON_FRUITS)], CollisionType.IgnoreOnlyPawn, true, GrabMode.Enabled)
			fruit:SetLifeSpan(FRUIT_LIFESPAN)
			fruit:AddImpulse(direction * CANNON_SPEED * (0.85 + math.random() * 0.3), true)
		end
	end

	Switch(button_spot, "fire", "fire", Fire, nil, false, "PushButton", CANNON_COOLDOWN)
end

-- The cannon's target: a wall of carton boxes laid like bricks across its line of fire (along the spot's Y), stacked again by the button beside it
local BOX_WALL_ASSET = "nanos-world::SM_CartonBox_02"
local BOX_SIZE = Vector(42, 71, 44.5)   -- SM_CartonBox_02, pivot at the base
local BOX_WALL_COLUMNS = 9
local BOX_WALL_ROWS = 5

local function SpawnBoxWall(wall_spot, button_spot)
	local boxes = {}

	local function Stack()
		for _, box in ipairs(boxes) do
			if (box:IsValid()) then box:Destroy() end
		end
		boxes = {}
		for row = 0, BOX_WALL_ROWS - 1 do
			-- Every other row is one box shorter and shifted half a box, like bricks; the top row loses its two end boxes too, which would hang half off the row under them
			local count = BOX_WALL_COLUMNS - row % 2 - (row == BOX_WALL_ROWS - 1 and 2 or 0)
			for column = 1, count do
				local y = (column - (count + 1) / 2) * BOX_SIZE.Y
				local box = Prop(Playground.At(wall_spot, 0, y, row * (BOX_SIZE.Z + 0.5) + 0.5), Rotator(0, wall_spot.rotation.Yaw, 0), BOX_WALL_ASSET, CollisionType.Normal, true, GrabMode.Enabled)
				boxes[#boxes + 1] = Playground.Track(box)
			end
		end
	end

	Stack()
	Switch(button_spot, "stack", "stack", Stack, nil, false, "PushButton")
end

-- Lookout tower lift: a cage riding the hole in the middle of the deck (sandbox.py TOWER), sent to the other end by the button at the foot or on the deck
-- The cage's pieces (SM_Cube, centred) by their centre above the floor's top and their size: the floor, four corner posts, a roof frame and a rail on each closed (X) side
local LIFT_SPEED = 175
local LIFT_TINT = Color(0.9, 0.35, 0.05)
local LIFT_PIECES = {
	{ Vector(0, 0, -5), Vector(200, 200, 10) },
	{ Vector(96, 96, 110), Vector(8, 8, 220) }, { Vector(96, -96, 110), Vector(8, 8, 220) }, { Vector(-96, 96, 110), Vector(8, 8, 220) }, { Vector(-96, -96, 110), Vector(8, 8, 220) },
	{ Vector(96, 0, 216), Vector(8, 200, 8) }, { Vector(-96, 0, 216), Vector(8, 200, 8) }, { Vector(0, 96, 216), Vector(200, 8, 8) }, { Vector(0, -96, 216), Vector(200, 8, 8) },
	{ Vector(96, 0, 100), Vector(6, 192, 6) }, { Vector(-96, 0, 100), Vector(6, 192, 6) }, { Vector(96, 0, 50), Vector(6, 192, 6) }, { Vector(-96, 0, 50), Vector(6, 192, 6) },
}

local function SpawnLift(lift_spot, button_spot, top_button_spot)
	-- The cage's floor sits 10 above the grass at the foot, flush with the deck the top button stands on at the top
	local low = lift_spot.location + Vector(0, 0, 10)
	local high = Vector(low.X, low.Y, top_button_spot.location.Z)
	local travel = (high.Z - low.Z) / LIFT_SPEED
	local pieces = {}
	for _, piece in ipairs(LIFT_PIECES) do
		local mesh = Fixed(low + piece[1], Rotator(), CUBE, piece[2] / 100)
		mesh:SetMaterialColorParameter("Tint", LIFT_TINT)
		pieces[#pieces + 1] = { mesh = mesh, offset = piece[1] }
	end
	local is_up, moving = false, false

	local function Go()
		if (moving) then return end
		moving, is_up = true, not is_up
		for _, piece in ipairs(pieces) do
			piece.mesh:TranslateTo((is_up and high or low) + piece.offset, travel)
		end
		Playground.PlaySound(is_up and low or high, "nanos-world::A_Switch_Button_01")
		-- Lift music on the cage for the ride (Client/Index.lua)
		Events.BroadcastRemote("Playground:LiftMusic", Reliability.Reliable, pieces[1].mesh, travel)
		Timer.SetTimeout(function() moving = false end, travel * 1000)
	end

	Switch(button_spot, "ride", "ride", Go, nil, false, "PushButton")
	Switch(top_button_spot, "ride", "ride", Go, nil, false, "PushButton")
end

-- Fireworks from the launcher on the tower's deck: each press sends up a volley of shells that burst high above the map (the ts-fireworks asset pack;
-- the clients draw the trail and the burst, Client/Index.lua)
local FIREWORK_SHELLS = 5
local FIREWORK_INTERVAL = 350
local FIREWORK_SPEED = 6000
local FIREWORK_FUSE = 1500
local FIREWORK_COOLDOWN = 3000
local FIREWORK_BURSTS = {
	"ts-fireworks::PS_TS_Fireworks_Burst_Chrys",
	"ts-fireworks::PS_TS_Fireworks_Burst_Circle",
	"ts-fireworks::PS_TS_Fireworks_Burst_Palm",
	"ts-fireworks::PS_TS_Fireworks_Burst_Shaped",
	"ts-fireworks::PS_TS_Fireworks_Burst_ShellsWithinShells",
}

local function LaunchShell(location)
	local shell = Prop(location, Rotator(), "nanos-world::SM_None", CollisionType.StaticOnly, true, GrabMode.Disabled)
	shell:AddImpulse(Vector(math.random(-600, 600), math.random(-600, 600), FIREWORK_SPEED), true)
	Events.BroadcastRemote("Playground:FireworkLaunch", Reliability.Unreliable, shell)
	Timer.SetTimeout(function()
		if (not shell:IsValid()) then return end
		Events.BroadcastRemote("Playground:FireworkBurst", Reliability.Unreliable, shell:GetLocation(), FIREWORK_BURSTS[math.random(#FIREWORK_BURSTS)])
		shell:Destroy()
	end, FIREWORK_FUSE)
end

local function SpawnFireworks(launcher_spot, button_spot)
	Switch(button_spot, "launch", "launch", function()
		for i = 0, FIREWORK_SHELLS - 1 do
			Timer.SetTimeout(function() LaunchShell(launcher_spot.location) end, i * FIREWORK_INTERVAL)
		end
	end, nil, false, "PushButton", FIREWORK_COOLDOWN)
end

-- The button behind the crates' wall puts every prop of the yard and the crate pyramid back: all of them taken away first, then all spawned again, so no fresh
-- one lands on an old one
local YARD_RESET_COOLDOWN = 2000

local function SpawnYardReset(button_spot, slots)
	Switch(button_spot, "reset props", "reset props", function()
		for _, slot in ipairs(slots) do
			if (slot.entity and slot.entity:IsValid()) then slot.entity:Destroy() end
		end
		for _, slot in ipairs(slots) do
			Playground.Respawn(slot)
		end
	end, nil, false, "PushButton", YARD_RESET_COOLDOWN)
end

Playground.Setup("Physics", function()
	-- The slots the yard's reset button puts back
	local yard = {}

	for index, entry in ipairs(Playground.SpotsWith("Sandbox_ToolPad")) do
		for _, item in ipairs(TOOL_PADS[(index - 1) % #TOOL_PADS + 1]) do
			yard[#yard + 1] = LooseOn(entry.spot, item[2], item[3], item[1], item[4], item[5], item[6], item[7])
		end
	end

	for _, entry in ipairs(Playground.SpotsWith("Sandbox_PlazaProps")) do
		Scatter(entry.spot, yard)
	end

	local spot = Playground.Spot

	if (spot("Sandbox_BedCar")) then SpawnBedCar(spot("Sandbox_BedCar"), Playground.HasSandbox() and spot("Sandbox_BedCarButton")) end
	if (spot("Sandbox_CratePyramid")) then SpawnPyramid(spot("Sandbox_CratePyramid"), yard) end
	if (Playground.HasSandbox() and spot("Sandbox_YardResetButton")) then SpawnYardReset(spot("Sandbox_YardResetButton"), yard) end
	if (spot("Sandbox_PendulumBall") and spot("Sandbox_Pendulum")) then SpawnPendulum(spot("Sandbox_PendulumBall"), spot("Sandbox_Pendulum")) end
	if (spot("Sandbox_Elastics")) then SpawnElastics(spot("Sandbox_Elastics")) end
	if (spot("Sandbox_TireSwing")) then SpawnTireSwing(spot("Sandbox_TireSwing")) end
	if (spot("Sandbox_Seesaw")) then SpawnSeesaw(spot("Sandbox_Seesaw")) end
	if (spot("Sandbox_Chain")) then SpawnChain(spot("Sandbox_Chain")) end
	if (spot("Sandbox_PunchBag")) then SpawnPunchBag(spot("Sandbox_PunchBag")) end
	if (spot("Sandbox_SpeedBag")) then SpawnSpeedBag(spot("Sandbox_SpeedBag")) end
	if (spot("Sandbox_Trampoline")) then SpawnTrampoline(spot("Sandbox_Trampoline")) end

	if (spot("Sandbox_PlateDoorPlate") and spot("Sandbox_PlateDoorDoor")) then
		SpawnPlateDoor(spot("Sandbox_PlateDoorPlate"), spot("Sandbox_PlateDoorDoor"))
	end

	if (not Playground.HasSandbox()) then return end

	if (spot("Sandbox_LogicButton") and spot("Sandbox_LogicDoor") and spot("Sandbox_LogicLamp")) then
		SpawnLogic(spot("Sandbox_LogicButton"), spot("Sandbox_LogicDoor"), spot("Sandbox_LogicLamp"))
	end

	if (spot("Sandbox_BallDrop") and spot("Sandbox_BallDropButton")) then
		SpawnBallDrop(spot("Sandbox_BallDrop"), spot("Sandbox_BallDropButton"))
	end

	if (spot("Sandbox_Rocket") and spot("Sandbox_RocketButton")) then
		SpawnRocket(spot("Sandbox_Rocket"), spot("Sandbox_RocketButton"))
	end

	if (spot("Sandbox_Cannon") and spot("Sandbox_CannonButton")) then
		SpawnCannon(spot("Sandbox_Cannon"), spot("Sandbox_CannonButton"))
	end

	if (spot("Sandbox_BoxWall") and spot("Sandbox_BoxWallButton")) then
		SpawnBoxWall(spot("Sandbox_BoxWall"), spot("Sandbox_BoxWallButton"))
	end

	if (spot("Sandbox_Lift") and spot("Sandbox_LiftButton") and spot("Sandbox_LiftTopButton")) then
		SpawnLift(spot("Sandbox_Lift"), spot("Sandbox_LiftButton"), spot("Sandbox_LiftTopButton"))
	end

	if (spot("Sandbox_Firework") and spot("Sandbox_FireworkButton")) then
		SpawnFireworks(spot("Sandbox_Firework"), spot("Sandbox_FireworkButton"))
	end

	if (spot("Sandbox_RopeLights") and spot("Sandbox_RopeLightsButton")) then
		SpawnRopeLights(spot("Sandbox_RopeLights"), spot("Sandbox_RopeLightsButton"))
	end
end)
