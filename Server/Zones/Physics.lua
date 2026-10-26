-- Sandbox & physics toys: prop yard pads and loose props, a bed car with a thruster, crate pyramid, the joints & cables yard (pendulum, elastics, tire swing, seesaw, chain, punching bag, speed bag), trampoline, pressure plate farm gate, lever door, ball drop, rocket potty, wired rope lights, fruit cannon and box wall, lookout tower lift and fireworks
-- The toys a button drives (Sandbox's LogicButton) only spawn when Sandbox runs

local CUBE = "nanos-world::SM_Cube"
local CRATE = "nanos-world::SM_Crate_07"
local DARK = Color(0.03, 0.03, 0.03)

-- Where a lever, switch or classic button stands on a button pedestal spot: on its top, facing the spot's yaw
local function OnPedestal(spot)
	return Playground.Top(spot, 0), Rotator(0, spot.rotation.Yaw, 0)
end

-- A loose prop on a spot, at x, y in the spot's axes and lift above its top, that comes back when it is destroyed or carried far away (one_way: vehicles push it without feeling it)
local function LooseOn(spot, x, y, asset, lift, scale, yaw, roll, one_way)
	scale = scale or 1

	return Playground.PropSlot(Playground.At(spot, x, y, spot.top + lift), Rotator(0, spot.rotation.Yaw + (yaw or 0), roll or 0), asset, {
		scale = scale ~= 1 and Vector(scale, scale, scale) or nil,
		reach = PHYSICS_LOOSE_REACH,
		one_way = one_way
	})
end

-- The scatter deck, dealt from until empty, then shuffled again
local deck = {}

local function DealProp()
	if (#deck == 0) then
		for i, item in ipairs(PHYSICS_SCATTER_PROPS) do deck[i] = item end

		for i = #deck, 2, -1 do
			local j = math.random(i)
			deck[i], deck[j] = deck[j], deck[i]
		end
	end

	return table.remove(deck)
end

-- Props strewn over a marker spot's area (its scale x 100 cm), standing on the ground at the marker; their slots go into out
local function Scatter(spot, out)
	local sx, sy = spot.scale.X * 100, spot.scale.Y * 100
	local nx, ny = math.max(1, math.floor(sx / PHYSICS_SCATTER_CELL)), math.max(1, math.floor(sy / PHYSICS_SCATTER_CELL))
	local ground = { location = spot.location, rotation = spot.rotation, top = 0 }

	for i = 1, nx do
		for j = 1, ny do
			if (math.random() < PHYSICS_SCATTER_FILL) then
				local item = DealProp()
				local x = (i - (nx + 1) / 2) * sx / nx + math.random(-25, 25)
				local y = (j - (ny + 1) / 2) * sy / ny + math.random(-25, 25)

				out[#out + 1] = LooseOn(ground, x, y, item.asset, item.lift, item.scale, math.random(0, 359), item.roll, item.one_way)
			end
		end
	end
end

-- A car on the grass built like the sandbox does it: a bed for a chassis and four Wheel Gun wheels on cables, the wheels off until someone turns them on, and a thruster on its back (off)
-- Its button puts it back if it is not home, then fires the thruster for a moment, up the ramp ahead of it
local BED_HALF = Vector(95, 64, 40)    -- where the wheels go on SM_Bed's sides: half length, half width, height (unscaled)
local TIRE = "nanos-world::SM_Offroad_Tire"
local TIRE_CONFIG = { offset = Vector(0, -20, 0), direction = Vector(0, -1, 0) }   -- Sandbox's WHEELS_CONFIG entry for the tire (that global is not exported to other packages)
local BED_MASS = 100
local BED_THRUST = 700000
local BED_BURN = 2000
local BED_HOME = 150                   -- further than this from home it is put back before a launch
local BED_RESET = 8000                 -- ms after a launch it is put back home anyway
local BED_REACH = 3000

local function SpawnBedCar(spot, button_spot)
	-- The current car's thruster and wheels
	local thruster, wheels = nil, {}

	local slot = Playground.Slot(function()
		-- Not grabbable: picking it up tears the wheels off
		local bed = Prop(spot.location + Vector(0, 0, 45), Rotator(0, spot.rotation.Yaw, 0), "nanos-world::SM_Bed", CollisionType.Normal, true, GrabMode.Disabled)
		bed:SetMassOverride(BED_MASS)

		local bed_quat = bed:GetRotation():Quaternion()
		local parts = {}
		wheels = {}

		for _, x in ipairs({ -BED_HALF.X, BED_HALF.X }) do
			for _, side in ipairs({ -1, 1 }) do
				-- WheelGun.OnSpawnWheel with the hit on the side face: its normal (±Y) sets the wheel's facing, the offset puts it beside the face
				local relative = Vector(x, side * BED_HALF.Y, BED_HALF.Z)
				local wheel_quat = bed_quat * Rotator(0, side * 90, 0):Quaternion() * TIRE_CONFIG.direction:ToOrientationQuat()
				local hit = bed:GetLocation() + bed_quat:RotateVector(relative)
				local location = hit - wheel_quat:RotateVector(TIRE_CONFIG.offset)

				-- Its config too: Activate reads the drive direction from it
				local wheel = Wheel(location, wheel_quat:Rotator(), TIRE, 2000000, false, side < 0, nil, TIRE_CONFIG)

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
		thruster = Playground.Track(Thruster(bed:GetLocation(), Rotator(), nil, nil, BED_THRUST, false))
		thruster:AttachTo(bed, AttachmentRule.SnapToTarget, "", 1)
		thruster:SetRelativeLocation(Vector(-BED_HALF.X - 20, 0, 50))
		thruster:SetRelativeRotation(Rotator())
		parts[#parts + 1] = thruster

		-- The car comes and goes as one
		bed:Subscribe("Destroy", function()
			for _, part in ipairs(parts) do
				if (part:IsValid()) then part:Destroy() end
			end
		end)

		return bed
	end, BED_REACH)

	if (not slot or not button_spot) then return end

	local burn_timer, reset_timer = nil, nil

	Playground.PushButton(button_spot, "launch", function()
		local bed = slot.entity
		if (not bed or not bed:IsValid() or bed:GetLocation():Distance(slot.home) > BED_HOME) then
			Playground.Respawn(slot)
		end

		if (not thruster or not thruster:IsValid()) then
			Console.Warn("Playground: the bed car has no thruster to launch")
			return
		end

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
	end, BED_BURN + 500)
end

-- Crate pyramid, 4 / 3 / 2 / 1 along the pad's X, to knock over with the physics gun; their slots go into out
local CRATE_SIZE = 60

local function SpawnPyramid(spot, out)
	for layer = 0, 3 do
		local count = 4 - layer

		for i = 0, count - 1 do
			local along = (i - (count - 1) / 2) * (CRATE_SIZE + 2)
			out[#out + 1] = LooseOn(spot, along, 0, CRATE, 1 + layer * CRATE_SIZE)
		end
	end
end

-- A small dark hook bolted under a beam, its top at point (the beam's underside); cables start at its bottom so they visibly hang from the beam
local HOOK = 8

local function Hook(point)
	return Playground.Fixed(point - Vector(0, 0, HOOK / 2), Rotator(), CUBE, Vector(HOOK, HOOK, HOOK) / 100, DARK)
end

-- Pendulum: ball hanging from the beam on a limited cable, spawned at rest straight under its hook
local PENDULUM_LENGTH = 330

local function SpawnPendulum(beam_spot)
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

-- A cable from a hook under a beam at from to a point on an entity (in its unscaled space), drawn taut; limit: its length; soft: springy (stiffness, damping) instead of rigid
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

-- A physics shape of the joints yard, never respawned
local function Shape(location, rotation, asset, scale, tint, grab)
	local prop = Playground.Track(Prop(location, rotation or Rotator(), asset, CollisionType.Normal, true, grab or GrabMode.Enabled))

	if (scale) then prop:SetScale(scale) end
	if (tint) then prop:SetMaterialColorParameter("Tint", tint) end

	return prop
end

-- Elastics: bouncy balls on long, soft elastics under one beam, each longer than the last; pull one down or jump into it. The elastics look like the Elastic Gun's, tinted like their ball
local ELASTIC_SCALE = 0.5              -- SM_Sphere radius 50
local ELASTIC_STIFFNESS = 12
local ELASTIC_DAMPING = 0.05

local function SpawnElastics(spot)
	for _, elastic in ipairs(PHYSICS_ELASTICS) do
		local top = Playground.At(spot, 0, elastic.y, 0)
		local ball = Shape(top - Vector(0, 0, elastic.length + 50 * ELASTIC_SCALE), Rotator(), "nanos-world::SM_Sphere", Vector(ELASTIC_SCALE, ELASTIC_SCALE, ELASTIC_SCALE), elastic.tint)
		ball:SetMaterialScalarParameter("Roughness", 0)
		ball:SetPhysicalMaterial("nanos-world::PM_RubberBouncy")
		ball:SetMassOverride(10)
		ball:SetPhysicsDamping(0, 0)

		local cable = Tie(top, ball, Vector(0, 0, 50), elastic.length, true, ELASTIC_STIFFNESS, ELASTIC_DAMPING, 4)
		cable:SetMaterial("nanos-world::M_Default_Masked_Lit")
		cable:SetMaterialColorParameter("Tint", elastic.tint)
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

local function SpawnSeesaw(spot)
	local middle = spot.location + Vector(0, 0, PLANK.Z / 2)
	local plank = Shape(middle, Rotator(0, spot.rotation.Yaw, 0), CUBE, PLANK / 100, PHYSICS_ORANGE, GrabMode.Disabled)
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

local function SpawnChain(spot)
	local above, above_relative = nil, nil
	local z = spot.location.Z - 2

	for i = 1, CHAIN_LINKS do
		z = z - CHAIN_GAP - CHAIN_CUBE / 2

		local cube = Shape(Vector(spot.location.X, spot.location.Y, z), Rotator(), CUBE, Vector(CHAIN_CUBE, CHAIN_CUBE, CHAIN_CUBE) / 100, PHYSICS_TINTS[(i - 1) % #PHYSICS_TINTS + 1])

		if (above) then
			TieTo(above, above_relative, cube, Vector(0, 0, 50), CHAIN_GAP, true, 1000, 10)
		else
			Tie(spot.location, cube, Vector(0, 0, 50), CHAIN_GAP, true, 1000, 10)
		end

		above, above_relative = cube, Vector(0, 0, -50)
		z = z - CHAIN_CUBE / 2
	end
end

-- A bag hanging under a hook on a short rigid hanger, free to swing and turn like a ball joint
local function HangBag(spot, asset, size, hanger, tint, mass, width)
	local top = spot.location - Vector(0, 0, HOOK)
	local bag = Shape(top - Vector(0, 0, hanger + size.Z / 2), Rotator(), asset, size / 100, tint, GrabMode.Disabled)
	bag:SetMassOverride(mass)

	local cable = Playground.Track(Cable(top, true))
	cable:AttachStartTo(Hook(spot.location), Vector(0, 0, -50))
	cable:SetLinearLimits(ConstraintMotion.Locked, ConstraintMotion.Locked, ConstraintMotion.Locked)
	cable:SetAngularLimits(ConstraintMotion.Free, ConstraintMotion.Free, ConstraintMotion.Free)
	cable:SetCableSettings(hanger, 2, 1)
	cable:SetRenderingSettings(width, 4, 1)
	cable:AttachEndTo(bag, Vector(0, 0, 50), nil, Vector(0, 0, hanger / size.Z * 100))
end

-- Punching bag: a heavy cylinder; speed bag: a small teardrop-ish bag at head height, quick to swing back (its hanger long enough to bring it down to face height under the 200 beam)
local function SpawnPunchBag(spot)
	HangBag(spot, "nanos-world::SM_Cylinder", Vector(34, 34, 75), 20, Color(0.55, 0.05, 0.04), 30, 3)
end

local function SpawnSpeedBag(spot)
	HangBag(spot, "nanos-world::SM_Sphere", Vector(26, 26, 34), 40, Color(0.6, 0.08, 0.05), 3, 2)
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

			Timer.SetTimeout(function()
				if (entity:IsValid()) then entity:SetJumpZVelocity(jump) end
			end, 500)
		elseif (entity:IsA(Prop)) then
			entity:AddImpulse(Vector(0, 0, TRAMPOLINE_LAUNCH), true)
		else
			return
		end

		Playground.PlaySound(spot.location + Vector(0, 0, TRAMPOLINE_TOP), "nanos-world::A_WoodSpring")
	end)
end

-- A sliding door at a door spot (SM_Cube is centred, the spot sits at the door's base); returns a function that opens or closes it
local DOOR_RISE = 310

local function SlidingDoor(spot)
	-- Up to the lintel's underside (sandbox.py door_frame: 320 above the ground, the spot on the grass at 5)
	local closed = spot.location + Vector(0, 0, 157.5)
	local door = Playground.Fixed(closed, spot.rotation, CUBE, Vector(0.2, 3.4, 3.15), PHYSICS_ORANGE)
	local is_open = false

	return function(open)
		if (open == is_open) then return end
		is_open = open

		door:TranslateTo(closed + Vector(0, 0, open and DOOR_RISE or 0), 1.2)
		Playground.PlaySound(closed, "nanos-world::A_Switch_Button_01")
	end
end

-- Farm gate at a door spot: two leaves of rails hinged on the frame's jambs, swinging open away from the spot's -X side (where its plate is) and back; returns a function that opens or closes it
-- Each leaf is a set of bars attached to an invisible hinge, which turns
local GATE_HALF = 170                  -- a leaf's length, hinge to middle (sandbox.py door_frame: 340 between the jambs)
local GATE_RAILS = { 40, 110, 180, 250 }
local GATE_SWING = 1.0

local function FarmGate(spot)
	local yaw = spot.rotation.Yaw
	local hinges = {}

	for _, side in ipairs({ -1, 1 }) do
		local hinge = Playground.Fixed(Playground.At(spot, 0, side * GATE_HALF, 0), Rotator(0, yaw, 0), "nanos-world::SM_None")

		-- Bars by their centre along the leaf (from the gate's middle, outwards) and height, size and roll
		local bars = {}
		for _, z in ipairs(GATE_RAILS) do bars[#bars + 1] = { GATE_HALF / 2, z, Vector(8, GATE_HALF - 4, 10), 0 } end
		bars[#bars + 1] = { GATE_HALF - 6, 145, Vector(10, 10, 240), 0 }
		bars[#bars + 1] = { 6, 145, Vector(10, 10, 240), 0 }

		-- The brace, from the hinge's foot up to the middle's top
		local rise, run = GATE_RAILS[#GATE_RAILS] - GATE_RAILS[1], GATE_HALF - 12
		bars[#bars + 1] = { GATE_HALF / 2, 145, Vector(6, math.sqrt(rise * rise + run * run), 8), side * math.deg(math.atan(rise, run)) }

		for _, bar in ipairs(bars) do
			local mesh = Playground.Fixed(Playground.At(spot, 0, side * bar[1], bar[2]), Rotator(0, yaw, bar[4]), CUBE, bar[3] / 100, PHYSICS_ORANGE)
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

		if (close_timer) then
			Timer.ClearTimeout(close_timer)
			close_timer = nil
		end

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

-- Lever door: the lever slides the door up and lights the lamp, pulling it again closes it
local function SpawnLogic(button_spot, door_spot, lamp_spot)
	local set_open = SlidingDoor(door_spot)

	-- The lamp spot is a marker on the lintel's front, its local +Y pointing away from the door
	local lamp = Playground.Fixed(lamp_spot.location, Rotator(), "nanos-world::SM_Sphere", Vector(0.3, 0.3, 0.3))
	local light = Playground.Track(Light(Playground.At(lamp_spot, 0, 40, 0), Rotator(), Color(1, 0.75, 0.3), LightType.Point, 30, 900))
	light:SetVisibility(false)

	local function Set(open)
		set_open(open)
		light:SetVisibility(open)
		lamp:SetMaterialColorParameter("Emissive", open and Color(10, 7, 2) or Color.BLACK)
	end

	local location, rotation = OnPedestal(button_spot)
	Playground.Button(location, rotation, "open", "close", function() Set(true) end, function() Set(false) end, { kind = "Lever" })
end

-- Ball drop: every press rains a load of bouncy balls from the chute's ring onto the pad; they vanish after a while
local BALL_DROP_HEIGHT = 650
local BALL_DROP_COUNT = 15
local BALL_LIFESPAN = 25

local function SpawnBallDrop(pad_spot, button_spot)
	local function Drop()
		for i = 1, BALL_DROP_COUNT do
			Timer.SetTimeout(function()
				-- Sandbox's own ball picks its random size and color, and keeps to the server's max_bouncy_balls like the spawn menu
				if (Sandbox.IsUnderSpawnLimit and not Sandbox.IsUnderSpawnLimit("BouncyBall")) then return end

				local location = pad_spot.location + Vector(math.random(-110, 110), math.random(-110, 110), BALL_DROP_HEIGHT)
				BouncyBall(location, Rotator()):SetLifeSpan(BALL_LIFESPAN)
			end, i * 80)
		end
	end

	Playground.PushButton(button_spot, "drop balls", Drop)
end

-- Rocket potty: a portable toilet on the pad with a sandbox thruster on each side, wired to a sandbox button; each press puts it back on the pad if it flew off, then fires them for a moment
-- The thrusters only show it (flame and sound, next to no force): the lift is one force straight up on the potty itself, which acts through its middle, so it rises straight instead of tipping over whichever way its weight leans
local ROCKET = "nanos-world::SM_Portapotty"
local ROCKET_DOOR = "nanos-world::SM_Portapotty_Door"
local ROCKET_DOOR_AT = Vector(58, 31, 0)   -- the door's hinge in its doorway on the potty's +X face
local ROCKET_FORCE = 150000
local ROCKET_BURN = 3000
local ROCKET_MASS = 50
local ROCKET_SIDE = 74                 -- booster distance from the middle: SM_Portapotty is 57 to its side, the thruster 16 thick at scale 0.5
local ROCKET_BOOSTER_Z = 110           -- about its middle's height
local ROCKET_STEADY = 4                -- angular damping, against any spin a bump starts
local ROCKET_HOME = 150                -- further than this from the pad it is rebuilt before a launch
local ROCKET_BOOM_HEIGHT = 2500        -- above the pad it blows up (no damage) like a grenade
local ROCKET_RESPAWN = 3000            -- ms after that a fresh one stands on the pad
local ROCKET_WATCH = 150               -- ms between height checks while it flies

local function SpawnRocket(pad_spot, button_spot)
	local home = pad_spot.location + Vector(0, 0, pad_spot.top + 1)

	-- Its door towards the button
	local facing = Rotator(0, (button_spot.location - home):ToOrientationRotator().Yaw, 0)
	local location, rotation = OnPedestal(button_spot)
	local button = Playground.Button(location, rotation, "launch", "launch", nil, nil, { switchable = false })
	local potty, thrusters, burn_timer = nil, {}, nil

	-- A fresh potty, its door and its thrusters on the pad, wired to the button (the wire is what fires them when the button activates)
	local function Build()
		if (potty and potty:IsValid()) then potty:Destroy() end

		potty = Playground.Track(Prop(home, facing, ROCKET, CollisionType.Normal, true, GrabMode.Enabled))
		potty:SetMassOverride(ROCKET_MASS)
		potty:SetPhysicsDamping(0, ROCKET_STEADY)

		local door = Playground.Track(StaticMesh(home, facing, ROCKET_DOOR))
		door:AttachTo(potty, AttachmentRule.SnapToTarget, "", 0)
		door:SetRelativeLocation(ROCKET_DOOR_AT)

		-- One booster on each side, clear of the ground: its force points along its X, pitched up so it pushes the potty upwards
		button:UnlinkAllEntities()
		thrusters = {}

		for _, side in ipairs({ -1, 1 }) do
			local thruster = Playground.Track(Thruster(home, Rotator(), nil, nil, 1, false))
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
		if (watch_timer) then
			Timer.ClearInterval(watch_timer)
			watch_timer = nil
		end

		if (not potty:IsValid()) then return end

		local at = potty:GetLocation()
		potty:Destroy()

		local grenade = Grenade(at, Rotator(), "nanos-world::SM_None", "nanos-world::P_Grenade_Special", "nanos-world::A_Explosion_Large", CollisionType.StaticOnly, false)
		grenade:SetDamage(0, 0, 0, 0, 1)
		grenade:Explode()
		Playground.PlaySound(at, "nanos-world::A_Explosion_Large", 12000, 1)

		respawn_timer = Timer.SetTimeout(function()
			respawn_timer = nil
			Build()
		end, ROCKET_RESPAWN)
	end

	-- Overrides Playground.Button's: the potty is rebuilt before the base activates the wired thrusters
	button.Activate = function(self, ...)
		if (respawn_timer) then
			Timer.ClearTimeout(respawn_timer)
			respawn_timer = nil
		end

		if (not potty:IsValid() or potty:GetLocation():Distance(home) > ROCKET_HOME) then Build() end

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
	local location, rotation = OnPedestal(button_spot)
	local button = Playground.Button(location, rotation, "lights on", "lights off")

	for i = 1, ROPE_LIGHTS_COUNT do
		local at = beam_spot.location + Vector((i - (ROPE_LIGHTS_COUNT + 1) / 2) * ROPE_LIGHTS_SPAN / (ROPE_LIGHTS_COUNT - 1), 0, -20)
		local hook = Playground.Fixed(at, Rotator(), CUBE, Vector(0.1, 0.1, 0.05))
		local light = Playground.Track(RopeLight(at - Vector(0, 0, 100), Vector(), Rotator(), Vector(0, 0, -1), hook))

		light:Deactivate()
		button:LinkEntity(light, true, Color.BLACK)
	end
end

-- Fruit cannon: each press fires a load of fruit at once from the muzzle (playground_props.py FruitCannon: local (0, 100, 87), barrel pitched 15) at the box wall, with a grenade's blast on the muzzle
local CANNON_MUZZLE = Vector(0, 140, 87)
local CANNON_PITCH = 5                 -- lower than the barrel (15): at CANNON_SPEED the fruits reach the wall 10 m away low down
local CANNON_SPEED = 4000
local CANNON_LOAD = 10
local CANNON_SPREAD = 16               -- degrees sideways, CANNON_RISE up and down, and each fruit 15% faster or slower
local CANNON_RISE = 6
local CANNON_CLUSTER = 50              -- the fruits start scattered this far round the muzzle, so they do not spawn inside each other
local CANNON_COOLDOWN = 1500           -- the button's: it takes no press while the cannon reloads
local CANNON_BLAST_SCALE = 0.75
local FRUIT_LIFESPAN = 15

local function Spread(range)
	return (math.random() * 2 - 1) * range
end

local function SpawnCannon(cannon_spot, button_spot)
	local muzzle = Playground.At(cannon_spot, CANNON_MUZZLE.X, CANNON_MUZZLE.Y, CANNON_MUZZLE.Z)
	local yaw = Playground.FrontYaw(cannon_spot)
	local forward = Rotator(CANNON_PITCH, yaw, 0):GetForwardVector()

	local function Fire()
		local blast = Playground.Track(Particle(muzzle, Rotator(CANNON_PITCH, yaw, 0), "nanos-world::P_Explosion", true, true))
		blast:SetScale(Vector(CANNON_BLAST_SCALE, CANNON_BLAST_SCALE, CANNON_BLAST_SCALE))
		Playground.PlaySound(muzzle, "nanos-world::A_Explosion_Large", 4000)

		for _ = 1, CANNON_LOAD do
			local direction = Rotator(CANNON_PITCH + Spread(CANNON_RISE), yaw + Spread(CANNON_SPREAD), 0):GetForwardVector()
			local offset = Vector(Spread(1), Spread(1), Spread(1)) * CANNON_CLUSTER
			local fruit = Prop(muzzle + forward * CANNON_CLUSTER + offset, Rotator(math.random(0, 359), math.random(0, 359), 0), PHYSICS_CANNON_FRUITS[math.random(#PHYSICS_CANNON_FRUITS)], CollisionType.IgnoreOnlyPawn, true, GrabMode.Enabled)

			fruit:SetLifeSpan(FRUIT_LIFESPAN)
			fruit:AddImpulse(direction * CANNON_SPEED * (0.85 + math.random() * 0.3), true)
		end
	end

	Playground.PushButton(button_spot, "fire", Fire, CANNON_COOLDOWN)
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
	Playground.PushButton(button_spot, "stack", Stack)
end

-- Lookout tower lift: a cage riding the hole in the middle of the deck (sandbox.py TOWER), sent to the other end by the button at the foot or on the deck
-- The cage's pieces (SM_Cube, centred) by their centre above the floor's top and their size: the floor, four corner posts, a roof frame and two rails on each closed (X) side
local LIFT_SPEED = 175
local LIFT_PIECES = {
	{
		offset = Vector(0, 0, -5),
		size = Vector(200, 200, 10)
	},
	{
		offset = Vector(96, 96, 110),
		size = Vector(8, 8, 220)
	},
	{
		offset = Vector(96, -96, 110),
		size = Vector(8, 8, 220)
	},
	{
		offset = Vector(-96, 96, 110),
		size = Vector(8, 8, 220)
	},
	{
		offset = Vector(-96, -96, 110),
		size = Vector(8, 8, 220)
	},
	{
		offset = Vector(96, 0, 216),
		size = Vector(8, 200, 8)
	},
	{
		offset = Vector(-96, 0, 216),
		size = Vector(8, 200, 8)
	},
	{
		offset = Vector(0, 96, 216),
		size = Vector(200, 8, 8)
	},
	{
		offset = Vector(0, -96, 216),
		size = Vector(200, 8, 8)
	},
	{
		offset = Vector(96, 0, 100),
		size = Vector(6, 192, 6)
	},
	{
		offset = Vector(-96, 0, 100),
		size = Vector(6, 192, 6)
	},
	{
		offset = Vector(96, 0, 50),
		size = Vector(6, 192, 6)
	},
	{
		offset = Vector(-96, 0, 50),
		size = Vector(6, 192, 6)
	}
}

local function SpawnLift(lift_spot, button_spot, top_button_spot)
	-- The cage's floor sits 10 above the grass at the foot, flush with the deck the top button stands on at the top
	local low = lift_spot.location + Vector(0, 0, 10)
	local high = Vector(low.X, low.Y, top_button_spot.location.Z)
	local travel = (high.Z - low.Z) / LIFT_SPEED
	local pieces = {}

	for _, piece in ipairs(LIFT_PIECES) do
		local mesh = Playground.Fixed(low + piece.offset, Rotator(), CUBE, piece.size / 100, PHYSICS_ORANGE)
		pieces[#pieces + 1] = { mesh = mesh, offset = piece.offset }
	end

	local is_up, moving = false, false

	local function Go()
		if (moving) then return end
		moving, is_up = true, not is_up

		for _, piece in ipairs(pieces) do
			piece.mesh:TranslateTo((is_up and high or low) + piece.offset, travel)
		end

		Playground.PlaySound(is_up and low or high, "nanos-world::A_Switch_Button_01")

		-- Lift music on the cage for the ride (Client/Effects.lua)
		Events.BroadcastRemote("Playground:LiftMusic", Reliability.Reliable, pieces[1].mesh, travel)

		Timer.SetTimeout(function() moving = false end, travel * 1000)
	end

	Playground.PushButton(button_spot, "ride", Go)
	Playground.PushButton(top_button_spot, "ride", Go)
end

-- Fireworks from the launcher on the tower's deck: each press sends up a volley of shells that burst high above the map (the ts-fireworks asset pack; the clients draw the trail and the burst, Client/Effects.lua)
local function LaunchShell(location)
	local config = PHYSICS_FIREWORKS
	local shell = Prop(location, Rotator(), "nanos-world::SM_None", CollisionType.StaticOnly, true, GrabMode.Disabled)
	shell:AddImpulse(Vector(math.random(-600, 600), math.random(-600, 600), config.speed), true)

	Events.BroadcastRemote("Playground:FireworkLaunch", Reliability.Unreliable, shell)

	Timer.SetTimeout(function()
		if (not shell:IsValid()) then return end

		Events.BroadcastRemote("Playground:FireworkBurst", Reliability.Unreliable, shell:GetLocation(), PHYSICS_FIREWORK_BURSTS[math.random(#PHYSICS_FIREWORK_BURSTS)])
		shell:Destroy()
	end, config.fuse)
end

local function SpawnFireworks(launcher_spot, button_spot)
	local config = PHYSICS_FIREWORKS

	Playground.PushButton(button_spot, "launch", function()
		for i = 0, config.shells - 1 do
			Timer.SetTimeout(function() LaunchShell(launcher_spot.location) end, i * config.interval)
		end
	end, config.cooldown)
end

-- The button behind the crates' wall puts every prop of the yard and the crate pyramid back: all of them taken away first, then all spawned again, so no fresh one lands on an old one
local YARD_RESET_COOLDOWN = 2000

local function SpawnYardReset(button_spot, slots)
	Playground.PushButton(button_spot, "reset props", function()
		for _, slot in ipairs(slots) do
			if (slot.entity and slot.entity:IsValid()) then slot.entity:Destroy() end
		end

		for _, slot in ipairs(slots) do
			Playground.Respawn(slot)
		end
	end, YARD_RESET_COOLDOWN)
end

Playground.Setup("Physics", function()
	local spot = Playground.Spot

	-- The slots the yard's reset button puts back
	local yard = {}

	for index, entry in ipairs(Playground.SpotsWith("Sandbox_ToolPad")) do
		for _, item in ipairs(PHYSICS_TOOL_PADS[(index - 1) % #PHYSICS_TOOL_PADS + 1]) do
			yard[#yard + 1] = LooseOn(entry.spot, item.x, item.y, item.asset, item.lift, item.scale, item.yaw, item.roll, item.one_way)
		end
	end

	for _, entry in ipairs(Playground.SpotsWith("Sandbox_PlazaProps")) do
		Scatter(entry.spot, yard)
	end

	if (spot("Sandbox_CratePyramid")) then SpawnPyramid(spot("Sandbox_CratePyramid"), yard) end
	if (spot("Sandbox_PendulumBall") and spot("Sandbox_Pendulum")) then SpawnPendulum(spot("Sandbox_Pendulum")) end
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

	-- Everything below is a Sandbox entity or needs its buttons
	if (not Playground.HasSandbox()) then return end

	if (spot("Sandbox_BedCar")) then SpawnBedCar(spot("Sandbox_BedCar"), spot("Sandbox_BedCarButton")) end
	if (spot("Sandbox_YardResetButton")) then SpawnYardReset(spot("Sandbox_YardResetButton"), yard) end

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
