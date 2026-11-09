-- Sandbox zone (sandbox.py), when Sandbox runs: the tool stalls (a button per tool gives it, decorative ToolGun meshes hang on the back walls), the physics guns on their table, each sandbox entity in the house, and what each stall shows

local CUBE = "nanos-world::SM_Cube"
local DARK = Color(0.03, 0.03, 0.03)
local WEIGHT_TINT = Color(0.05, 0.05, 0.05)

-- Sandbox entities are spawned this much above their spot's surface, to settle
local ENTITY_LIFT = 20

-- A tool gun left further than this from its bench, by nobody holding it, goes back on it at the next refill
local TOOL_REACH = 100

-- A painted prop of the stalls carried further than this is put back on the next refill
local SHOW_REACH = 1500

-- How much a balloon lifts, how far apart the house's three balloons' weights stand across the pad, and the shortest cord (the middle balloon's is 60 longer)
local BALLOON_LIFT = 100000
local BALLOON_SPREAD = 45
local BALLOON_CORD = 110

-- The spawner stall's items on their tables, lifted this much; a few need more than that
local ITEM_LIFT = 2
local ITEM_BALLOON_CORD = 70
local ITEM_LAMP_LIFT = 46.6            -- SM_Lamp_Lantern hangs from its pivot: its foot this far under it
local ITEM_THRUSTER = { 0.5, 8 }       -- its scale, and how far its nose sticks out past its pivot along its X at scale 1 (SM_Rocket_Thruster), which points down
local ITEM_TIRE = { 0.6, 51 }          -- its scale, and its radius at scale 1 (SM_Offroad_Tire stands, its axle along its Y towards the visitor)
local ITEM_TIRE_CONFIG = { offset = Vector(0, -20, 0), direction = Vector(0, -1, 0) }

-- Constrainers' show: a cube on a rope, a ball on an elastic; spawners': a rope light hanging from the awning on a short cord, off, and a sandbox button on a table wired to it
local SHOW_ROPE = 90
local SHOW_SPRING = 70
local SHOW_CUBE = 0.35
local SHOW_LAMP_CORD = 35

-- Gives a fresh tool to whoever pressed a stall's button no sooner than this (ms) after the last one
local GIVE_COOLDOWN = 1000

-- The house's TV hangs this high above the floor (sandbox.py TV), its speakers stand this far out from the wall under it
local TV_HEIGHT = 110
local SPEAKER_OUT = 12

-- The house's TV and the CCTV's monitor hang (on the wall, on the pole): Sandbox's hanging model, with gravity off
local HANGING_TV = "nanos-world::SM_TV_Hanging"

-- The CCTV's camera tilts this much down at the path; its spot is a marker, which only carries the yaw
local CCTV_CAMERA_PITCH = -30

-- The house's lamp hangs on a cable this long from a bracket this far out of the wall
local LAMP_CABLE = 18
local LAMP_BRACKET = 14

-- Wall switches (sandbox.py markers on the wall face, their local +Y out of it) at this size, like the street lamps'
local SWITCH_SCALE = 1.4

-- Entities that stand right on their spot's surface instead of ENTITY_LIFT above it
local ON_SURFACE = {
	TV = true,
	Door = true
}

-- The breakable melons in a square pyramid (the melon is a 27 x 28 ball): 3 x 3 resting on the pedestal, 2 x 2 in the pockets between them, one on top
local MELON_STEP = 27.5
local MELON_BASE_Z = -5.5

-- Entities shown as several copies, at these offsets on their spot
local COPIES = {
	Breakable = {}
}

for layer, count in ipairs({ 3, 2, 1 }) do
	for i = 1, count do
		for j = 1, count do
			-- Each layer half a step in from the one under it, a pocket's depth higher (step / sqrt 2) plus a little air to settle into
			local x, y = (i - (count + 1) / 2) * MELON_STEP, (j - (count + 1) / 2) * MELON_STEP
			table.insert(COPIES.Breakable, Vector(x, y, MELON_BASE_Z + (layer - 1) * (MELON_STEP / math.sqrt(2) + 0.5)))
		end
	end
end

-- The house's TV and lamp, the last ones spawned (their slots bring them back if they are destroyed)
local house_tv, house_lamp = nil, nil

-- The spawner stall's rope lights, wired to its button
local show_lamps = {}

-- A helper mesh goes with the entity it was made for
local function DestroyWith(entity, helper)
	entity:Subscribe("Destroy", function()
		if (helper:IsValid()) then helper:Destroy() end
	end)

	return entity
end

-- What each spawner tool spawns, the sandbox entity itself, on a table behind its button, the light off: each gets the class and the table spot and returns what it spawned
local ITEMS = {
	-- Tied to a small weight on the table; Balloon spawns 50 along the direction from the location it is given
	BalloonGun = function(class, spot)
		local weight = Playground.Fixed(spot.location + Vector(0, 0, 6), Rotator(), CUBE, Vector(0.12, 0.12, 0.12), WEIGHT_TINT)
		local balloon = class(spot.location + Vector(0, 0, 12 + ITEM_BALLOON_CORD - 50), Rotator(), nil, nil, nil, Vector(0, 0, 6), Rotator(), Vector(0, 0, 1), weight, BALLOON_LIFT, ITEM_BALLOON_CORD, "nanos-world::SM_Balloon_01")

		return DestroyWith(balloon, weight)
	end,
	ThrusterGun = function(class, spot)
		local thruster = class(spot.location + Vector(0, 0, ITEM_THRUSTER[1] * ITEM_THRUSTER[2] + ITEM_LIFT), Rotator(-90, spot.rotation.Yaw, 0), nil, nil, nil, false)
		thruster:SetScale(Vector(ITEM_THRUSTER[1], ITEM_THRUSTER[1], ITEM_THRUSTER[1]))

		return thruster
	end,
	-- Standing on its tread, held so it doesn't roll off
	WheelGun = function(class, spot)
		local wheel = class(spot.location + Vector(0, 0, ITEM_TIRE[1] * ITEM_TIRE[2] + ITEM_LIFT), Rotator(0, spot.rotation.Yaw, 0), nil, nil, false, false, ITEM_TIRE[1], ITEM_TIRE_CONFIG)
		wheel:SetGravityEnabled(false)

		return wheel
	end,
	-- On a small block on the table, pointing up
	TrailGun = function(class, spot)
		local block = Playground.Fixed(spot.location, Rotator(0, spot.rotation.Yaw, 0), CUBE, Vector(0.2, 0.2, 0.2), WEIGHT_TINT)
		local up = Vector(0, 0, 1)
		local trail = class(spot.location + Vector(0, 0, 20), up:ToOrientationRotator(), Vector(0, 0, 50), Rotator(90, 0, 0), up, block)

		return DestroyWith(trail, block)
	end,
	LightGun = function(class, spot)
		local lamp = class(spot.location + Vector(0, 0, ITEM_LAMP_LIFT + ITEM_LIFT), Rotator(0, spot.rotation.Yaw, 0), nil, nil, nil, "Lantern", SANDBOX_HOUSE_LAMP.color)
		lamp:Deactivate()

		return lamp
	end,
	ButtonGun = function(class, spot)
		return class(spot.location + Vector(0, 0, ITEM_LIFT), Rotator(0, spot.rotation.Yaw, 0), nil, nil, nil, true, "PushButton")
	end,
}

-- Gives a fresh tool to whoever pressed a stall's button, in their hands; like the spawn menu, what they held goes
local function GiveTool(class, player, causer)
	local character = (causer and causer:IsValid() and causer:IsA(Character)) and causer or (player and player:GetControlledCharacter())
	if (not character or not character:IsValid() or not character:IsA(Character)) then return end

	player = player or character:GetPlayer()
	if (not player or not player:IsValid() or not Sandbox.ValidateSpawnLimits(player, "tools")) then return end

	local held = character:GetPicked()
	if (held and held:IsValid()) then held:Destroy() end

	local tool = class(character:GetLocation(), Rotator())
	Sandbox.SpawnHistory.AddItemToHistory(player, tool)
	character:PickUp(tool)
end

-- A cable from a fixed point (a cable not attached at its start holds there) to the top of an entity (SM_Cube / SM_Ball_VR unscaled)
local function Hang(from, entity, top, length, soft, stiffness, damping)
	local cable = Playground.Track(Cable(from, true))
	cable:SetLinearLimits(ConstraintMotion.Limited, ConstraintMotion.Limited, ConstraintMotion.Limited, length, 0.25, soft, stiffness, damping)
	cable:SetCableSettings(length * 0.75, 10, 1)
	cable:SetRenderingSettings(3, 4, 1)
	cable:AttachEndTo(entity, Vector(0, 0, top))

	return cable
end

-- What the stalls show (sandbox.py STALL_SHOW), at markers under the awning (hooks) or on the floor, by kind: each gets its spot and its index among them
local SHOW = {
	Rope = function(spot, index)
		local cube = Playground.Track(Prop(spot.location - Vector(0, 0, SHOW_ROPE + 50 * SHOW_CUBE), Rotator(0, 20 * index, 0), CUBE, CollisionType.Normal, true, GrabMode.Enabled))
		cube:SetScale(Vector(SHOW_CUBE, SHOW_CUBE, SHOW_CUBE))
		cube:SetMaterialColorParameter("Tint", SANDBOX_SHOW_TINTS[index % #SANDBOX_SHOW_TINTS + 1])

		Hang(spot.location, cube, 50, SHOW_ROPE, true, 1000, 10)
	end,
	Spring = function(spot, index)
		local ball = Playground.Track(Prop(spot.location - Vector(0, 0, SHOW_SPRING + 70 * 0.3), Rotator(), "nanos-world::SM_Ball_VR", CollisionType.Normal, true, GrabMode.Enabled))
		ball:SetScale(Vector(0.3, 0.3, 0.3))

		Hang(spot.location, ball, 70, SHOW_SPRING, true, 40, 1)
	end,
	Lamp = function(spot)
		local hook = Playground.Fixed(spot.location, Rotator(), CUBE, Vector(0.03, 0.03, 0.03), DARK)
		local lamp = Playground.Track(RopeLight(spot.location - Vector(0, 0, SHOW_LAMP_CORD), Vector(), Rotator(), Vector(0, 0, -1), hook, SHOW_LAMP_CORD))
		lamp:Deactivate()

		show_lamps[#show_lamps + 1] = lamp
	end,
	Button = function(spot)
		local button = Playground.Button(spot.location, Rotator(0, spot.rotation.Yaw, 0), "light on", "light off")

		for _, lamp in ipairs(show_lamps) do
			if (lamp:IsValid()) then button:LinkEntity(lamp, true, Color.BLACK) end
		end
	end,
	Big = function(spot, index)
		local big = SANDBOX_SHOW_BIG[index % #SANDBOX_SHOW_BIG + 1]

		Playground.PropSlot(spot.location + Vector(0, 0, big.lift + 2), Rotator(0, 15 * index, 0), big.asset, {
			scale = Vector(big.scale, big.scale, big.scale),
			tint = SANDBOX_SHOW_TINTS[(index + 2) % #SANDBOX_SHOW_TINTS + 1],
			reach = SHOW_REACH
		})
	end,
	Giant = function(spot)
		local giant = SANDBOX_SHOW_GIANT

		Playground.PropSlot(spot.location + Vector(0, 0, giant.lift), Rotator(0, 30, 0), giant.asset, {
			scale = Vector(giant.scale, giant.scale, giant.scale),
			reach = SHOW_REACH
		})
	end,
}

-- Lights the house's lamp or puts it out: its Light and its bulb's glow, as Sandbox's RopeLight does
local function SetLampLit(is_on)
	if (not house_lamp or not house_lamp:IsValid()) then return end

	local light = house_lamp:GetValue("Light")
	if (not light or not light:IsValid()) then return end

	light:SetVisibility(is_on)
	house_lamp:SetMaterialColorParameter("Emissive", is_on and SANDBOX_HOUSE_LAMP.color * SANDBOX_HOUSE_LAMP.glow or Color.BLACK)
end

-- A switch (or another kind of LogicButton) on the wall at a sandbox.py marker: its plate faces its local +Z, rolled up and turned to face out of the wall
local function WallSwitch(spot, label_on, label_off, on_activate, on_deactivate, is_on, kind)
	return Playground.Button(spot.location, Rotator(0, spot.rotation.Yaw + 180, -90), label_on, label_off, on_activate, on_deactivate, { kind = kind or "Switch", is_on = is_on, scale = SWITCH_SCALE })
end

-- Turns a Sandbox TV (or a CCTV's monitor) into the hanging model, floating where it is
local function HangTV(tv)
	tv:SetMesh(HANGING_TV)
	tv:SetGravityEnabled(false)
	tv:SetValue("Model", HANGING_TV, true)

	return tv
end

-- Spawners of the entities that need more than (location, rotation): each gets the surface of its spot, the rotation a visitor in front of it looks along, its offset among COPIES and the spot itself
local CUSTOM_SPAWN = {
	-- The house's lamp: hangs on a short cable from a dark bracket out of the wall by the door (its spot on the wall's face), warm and dim
	RopeLight = function(class, location, _, _, spot)
		local out = spot.rotation:RotateVector(Vector(0, 1, 0))
		local bracket = Playground.Fixed(location + out * (LAMP_BRACKET / 2), spot.rotation, CUBE, Vector(0.03, LAMP_BRACKET / 100, 0.03), DARK)
		local tip = location + out * LAMP_BRACKET

		house_lamp = DestroyWith(class(tip - Vector(0, 0, LAMP_CABLE), Vector(), Rotator(), Vector(0, 0, -1), bracket, LAMP_CABLE), bracket)

		local light = house_lamp:GetValue("Light")
		if (light and light:IsValid()) then
			light:SetColor(SANDBOX_HOUSE_LAMP.color)
			light:SetIntensity(SANDBOX_HOUSE_LAMP.intensity)
		end

		SetLampLit(true)

		return house_lamp
	end,
	-- A melon of the pyramid, turned with it so it lies along the row; Sandbox breaks each one by itself
	-- Every melon has physics; the bottom layer has a strong angular damping, so the round melons slide instead of rolling apart under the ones on top
	Breakable = function(_, location, rotation, offset)
		local melon = Prop(location + Vector(0, 0, ENTITY_LIFT) + offset, rotation + Rotator(0, 90, 0), "nanos-world::SM_Fruit_Watermelon_01", CollisionType.Auto, true)

		if (offset.Z == MELON_BASE_Z) then
			melon:SetPhysicsDamping(0.01, 50)
		end

		return melon
	end,
	-- The monitor hangs on the pole at the gate; its camera, the Housing one, goes on the pole near its top ("Sandbox_CCTVCamera", tilted down at the path)
	CCTV = function(class, location, rotation)
		local tv = HangTV(class(location, rotation))
		local camera, mount = tv.camera, Playground.Spot("Sandbox_CCTVCamera")

		if (camera and camera:IsValid() and mount) then
			tv:SetCamera(nil, "nanos-world::SM_Camera_Housing")
			camera:SetLocation(mount.location)
			camera:SetRotation(Rotator(CCTV_CAMERA_PITCH, mount.rotation.Yaw, 0))
		end

		-- The cable starts hidden here, it can be shown again from the Context Menu
		tv:SetCableVisible(nil, false)

		return tv
	end,
	-- On the wall; Sandbox puts its speakers either side at its own height, so they go down on the floor, a little out from the wall, upright
	TV = function(class, location, rotation, _, spot)
		house_tv = HangTV(class(location, rotation))
		local out = spot.rotation:RotateVector(Vector(0, -SPEAKER_OUT, 0))

		for _, key in ipairs({ "SoundBox_01", "SoundBox_02" }) do
			local speaker = house_tv:GetValue(key)

			if (speaker and speaker:IsValid()) then
				local at = speaker:GetLocation()
				speaker:SetLocation(Vector(at.X, at.Y, location.Z - TV_HEIGHT) + out)
				speaker:SetRotation(Rotator(0, speaker:GetRotation().Yaw, 0))
			end
		end

		return house_tv
	end,
	-- A bare 102 cm panel with no stand, hung flat on the wall with gravity off; it faces its spot's local +Y, as the museum's do
	PhotoFrame = function(class, _, _, _, spot)
		local frame = class(spot.location, Rotator(0, spot.rotation.Yaw - 90, 0), nil, nil, nil, nil, SANDBOX_PHOTO_FRAME_IMAGE)
		frame:SetGravityEnabled(false)

		return frame
	end,
	-- Lying on the side table, switched off
	Flashlight = function(class, location, rotation)
		return class(location + Vector(0, 0, ENTITY_LIFT), rotation, nil, nil, nil, true)
	end,
	-- Upright and still: it is tall and narrow, with gravity it tips over
	Sign = function(class, location, rotation)
		local sign = class(location + Vector(0, 0, 12), rotation)
		sign:SetGravityEnabled(false)

		local text = sign:GetValue("TextRender")
		if (text and text:IsValid()) then text:SetText(SANDBOX_SIGN_TEXT) end

		return sign
	end,
	-- Three balloons, each tied to its own weight on the pad: tied to one point they all float to the same spot above it and pop on each other (Balloon pops on any hit over 1000), so the weights stand apart and the cords differ in length, and each balloon spawns right where its cord holds it
	-- If any of them pops, the set goes, weights included, so the slot (which follows the first) brings back all three instead of leaving two untethered
	Balloon = function(class, location, rotation)
		local weights, balloons = {}, {}
		local across = Rotator(0, rotation.Yaw, 0):GetRightVector()

		for i = 1, 3 do
			local at = location + across * ((i - 2) * BALLOON_SPREAD)
			weights[i] = Playground.Fixed(at, Rotator(), CUBE, Vector(0.2, 0.2, 0.12))

			-- Balloon spawns 50 along the direction from the location it is given
			local length = BALLOON_CORD + (i % 2) * 60
			balloons[i] = Playground.Track(class(at + Vector(0, 0, length - 50), Rotator(), nil, nil, nil, Vector(), Rotator(), Vector(0, 0, 1), weights[i], BALLOON_LIFT, length, "nanos-world::SM_Balloon_0" .. i))
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

-- The tool benches ("Sandbox_Tool_<class>"): the guns lying on them, two on the paired ones
local function SpawnBenchTools()
	for _, entry in ipairs(Playground.SpotsWith("Sandbox_Tool_")) do
		local name = entry.name:sub(#"Sandbox_Tool_" + 1)
		local class = Playground.FindClass(name)
		local apart = SANDBOX_PAIRED_APART[name]

		if (not class) then
			Console.Warn("Playground: sandbox tool '%s' not found", name)
		elseif (apart) then
			-- Two on the pedestal, side by side across it, one pointing each way
			local yaw = Playground.FrontYaw(entry.spot) + 90
			local across = Rotator(0, yaw, 0):GetRightVector()

			for k, side in ipairs({ -1, 1 }) do
				local location, rotation = Playground.LyingOnSide(name, Playground.Top(entry.spot, 0) + across * side * apart, Rotator(0, yaw + (side > 0 and 180 or 0), 90), 0.5)

				Playground.Slot(function()
					local tool = class(location, rotation)
					if (name == "PukeGun") then tool:SetValue("Option", SANDBOX_PUKE_OPTIONS[k], true) end
					return tool
				end, TOOL_REACH)
			end
		else
			-- Lying on its side along the bench, muzzle to the visitor's left, centred on it
			local location, rotation = Playground.LyingOnSide(name, Playground.Top(entry.spot, 0), Rotator(0, Playground.FrontYaw(entry.spot) + 90, 90), 0.5)
			Playground.Slot(function() return class(location, rotation) end, TOOL_REACH)
		end
	end
end

-- The stalls: decorative ToolGun meshes hanging on the back walls ("Sandbox_Display_ToolGun_*", the mesh's pivot and pitch) and a counter button per tool ("Sandbox_Give_<class>")
local function SpawnStalls()
	-- A plain Weapon held still, nobody can pick it up (the mesh is the game's, so the map cannot hold it as level art)
	for _, entry in ipairs(Playground.SpotsWith("Sandbox_Display_ToolGun_")) do
		local display = Playground.Track(Weapon(entry.spot.location, entry.spot.rotation, "nanos-world::SK_ToolGun", CollisionType.NoCollision, false))
		display:SetPickable(false)
	end

	for _, entry in ipairs(Playground.SpotsWith("Sandbox_Give_")) do
		local name = entry.name:sub(#"Sandbox_Give_" + 1)
		local class = Playground.FindClass(name)

		if (class) then
			local label = "get " .. name:gsub("(%l)(%u)", "%1 %2"):lower()
			Playground.Button(entry.spot.location, Rotator(0, entry.spot.rotation.Yaw, 0), label, label, function(player, causer) GiveTool(class, player, causer) end, nil, { kind = "PushButton", switchable = false, cooldown = GIVE_COOLDOWN })
		else
			Console.Warn("Playground: sandbox tool '%s' not found", name)
		end
	end
end

-- The spawner stall's tables: what each tool spawns
local function SpawnSpawnerItems()
	local tables = {}
	for _, entry in ipairs(Playground.SpotsWith("Sandbox_Item_")) do tables[entry.name:sub(#"Sandbox_Item_" + 1)] = entry.spot end

	for _, item in ipairs(SANDBOX_SPAWNER_ITEMS) do
		local class, spot = Playground.FindClass(item.class, { Prop }), tables[item.tool]

		if (class and spot and ITEMS[item.tool]) then
			Playground.Slot(function() return ITEMS[item.tool](class, spot) end)
		end
	end
end

-- What each stall shows: "Sandbox_Show<Kind><Stall><index>"; buttons last, wired to the lamps spawned before them
local function SpawnShows()
	local shows = Playground.SpotsWith("Sandbox_Show")

	for _, buttons in ipairs({ false, true }) do
		for index, entry in ipairs(shows) do
			local kind = entry.name:match("^Sandbox_Show(%u%l+)")
			if (SHOW[kind] and (kind == "Button") == buttons) then SHOW[kind](entry.spot, index) end
		end
	end
end

-- Each sandbox entity of the house ("Sandbox_Ent_<class>"), spawned like the spawn menu does: rotation is the look direction of a visitor facing the spot (from its -Y)
local function SpawnHouseEntities()
	for _, entry in ipairs(Playground.SpotsWith("Sandbox_Ent_")) do
		local name = entry.name:sub(#"Sandbox_Ent_" + 1)
		local class, custom = Playground.FindClass(name), CUSTOM_SPAWN[name]

		if (class or custom) then
			-- A marker (no mesh) is the surface itself, a placeholder its top
			local surface = entry.spot.mesh == "" and entry.spot.location or Playground.Top(entry.spot, 0)
			local rotation = Rotator(0, entry.spot.rotation.Yaw + 90, 0)
			local location = ON_SURFACE[name] and surface or surface + Vector(0, 0, ENTITY_LIFT)

			for _, offset in ipairs(COPIES[name] or { Vector() }) do
				Playground.Slot(function()
					if (custom) then return custom(class, surface, rotation, offset, entry.spot) end
					return class(location + offset, rotation)
				end)
			end
		else
			Console.Warn("Playground: sandbox entity '%s' not found", name)
		end
	end
end

-- The push button beside the house's TV plays the trailer on it and stops it again (or after SANDBOX_TRAILER_DURATION)
local function SpawnTrailerButton(spot)
	local trailer_button, trailer_timeout = nil, nil

	local function ClearTrailerTimeout()
		if (trailer_timeout) then
			Timer.ClearTimeout(trailer_timeout)
			trailer_timeout = nil
		end
	end

	trailer_button = WallSwitch(spot, "play trailer", "stop trailer", function()
		ClearTrailerTimeout()
		if (house_tv and house_tv:IsValid()) then house_tv:SetWebsite(nil, SANDBOX_TRAILER_URL) end

		trailer_timeout = Timer.SetTimeout(function()
			trailer_timeout = nil

			if (trailer_button and trailer_button:IsValid() and trailer_button.is_active) then
				trailer_button:Deactivate()
			end
		end, SANDBOX_TRAILER_DURATION)

		Timer.Bind(trailer_timeout, trailer_button)
	end, function()
		ClearTrailerTimeout()
		if (house_tv and house_tv:IsValid()) then house_tv:SetWebsite(nil, "") end
	end, false, "PushButton")
end

Playground.Setup("Sandbox", function()
	if (not Playground.HasSandbox()) then
		Console.Log("Playground: Sandbox not loaded, the tool benches stay empty")
		return
	end

	SpawnBenchTools()
	SpawnStalls()
	SpawnSpawnerItems()
	SpawnShows()
	SpawnHouseEntities()

	local trailer = Playground.Spot("Sandbox_TrailerButton")
	if (trailer) then SpawnTrailerButton(trailer) end

	-- The switch by the door, under the lamp, lights it; on to start with
	local light_switch = Playground.Spot("Sandbox_HouseLightSwitch")
	if (light_switch) then
		WallSwitch(light_switch, "turn on", "turn off", function() SetLampLit(true) end, function() SetLampLit(false) end, true)
	end
end)
