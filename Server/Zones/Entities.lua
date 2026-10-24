-- Native entities museum: one real entity per exhibit, on the display the level marks for it
-- Client-only classes (Sound, Billboard, Decal, Gizmo, WebUI, Widget3D, SceneCapture) and the info stand texts are in Client/

local PURPLE = Color(0.35, 0.1, 0.8)

-- Faces the plaza centre: the exhibit spots are turned towards it
local function Facing(spot)
	return Rotator(0, spot.rotation.Yaw, 0)
end

local Top = Playground.Top

-- default-characters' classes when it runs (its NPCs, AI off so they stay on their display), the bare classes otherwise
local function DefaultCharacter(name, location, rotation, fallback)
	local class = NanosWorldCharacters and NanosWorldCharacters[name]
	if (class) then return class(location, rotation, false) end
	return fallback(location, rotation)
end

local LIT, UNLIT = "nanos-world::M_Default_Masked_Lit", "nanos-world::M_Default_Masked_Unlit"

-- Scenery around an exhibit (lamp housings, a speaker): no collision, tinted, unlit for the parts that glow
local function Fixture(location, rotation, mesh, scale, color, unlit)
	local fixture = Playground.Track(StaticMesh(location, rotation, "nanos-world::" .. mesh, CollisionType.NoCollision))
	fixture:SetScale(scale)
	fixture:SetMaterial(unlit and UNLIT or LIT)
	fixture:SetMaterialColorParameter("Tint", color)
	return fixture
end

local DARK, GREY = Color(0.03, 0.03, 0.035), Color(0.25, 0.25, 0.27)

-- Glow of a light's visible source: its own color, pushed past 1 so it blooms
local function Glow(color)
	return Color(color.R * 6, color.G * 6, color.B * 6)
end

local POINT_COLOR, SPOT_COLOR, RECT_COLOR = Color(1, 0.6, 0.2), Color(0.3, 0.6, 1), Color(0.6, 1, 0.5)

-- The part of a light's fixture the light comes from (bulb, lens, softbox face): lit, in a pale tint of its color, glowing while the light is on
local function SetGlow(part, color, is_on)
	part:SetMaterialColorParameter("Emissive", is_on and Glow(color) or Color.BLACK)
end

local function GlowPart(location, rotation, mesh, scale, color)
	local part = Fixture(location, rotation, mesh, scale, Color(0.55 + color.R * 0.45, 0.55 + color.G * 0.45, 0.55 + color.B * 0.45))
	SetGlow(part, color, true)
	return part
end

-- Housings showing where each light comes from, spawned once beside the lights (basic shapes are 100 cm, pivot at their centre); a light's returns its glowing part
local FIXTURES = {
	-- A bare bulb on a thin stem
	LightPoint = function(spot)
		Fixture(Top(spot, 27), Rotator(), "SM_Cylinder", Vector(0.025, 0.025, 0.54), DARK)
		return GlowPart(Top(spot, 60), Rotator(), "SM_Sphere", Vector(0.12, 0.12, 0.15), POINT_COLOR)
	end,
	-- A stage can hanging from a gallows standing behind the display, its lens just above the light
	LightSpot = function(spot)
		local height = spot.top + 240
		Fixture(Playground.At(spot, 0, -80, height / 2), spot.rotation, "SM_Cylinder", Vector(0.07, 0.07, height / 100), DARK)
		Fixture(Playground.At(spot, 0, -40, height - 3), spot.rotation, "SM_Cube", Vector(0.06, 0.86, 0.06), DARK)
		Fixture(Top(spot, 220), Rotator(), "SM_Cylinder", Vector(0.3, 0.3, 0.36), DARK)
		return GlowPart(Top(spot, 201.5), Rotator(), "SM_Cylinder", Vector(0.26, 0.26, 0.02), SPOT_COLOR)
	end,
	-- A softbox on a stand, its glowing face where the rect light sits
	LightRect = function(spot)
		local facing = Facing(spot)
		local forward = facing:GetForwardVector()
		-- The pole runs from the stand up into the middle of the box, behind its face (SM_Cylinder is 100 tall, pivot at its centre)
		Fixture(Top(spot, 60) - forward * 4, Rotator(), "SM_Cylinder", Vector(0.04, 0.04, 1.2), DARK)
		Fixture(Top(spot, 120) - forward * 4, facing, "SM_Cube", Vector(0.06, 0.84, 0.54), DARK)
		return GlowPart(Top(spot, 120) - forward * 0.5, facing, "SM_Cube", Vector(0.01, 0.78, 0.48), RECT_COLOR)
	end,
	-- A speaker cabinet under the sound (the Sound itself only exists on the clients), cones on its front
	Sound = function(spot)
		local facing = Facing(spot)
		local forward = facing:GetForwardVector()
		local cone = Rotator(90, facing.Yaw, 0)
		Fixture(Top(spot, 30), facing, "SM_Cube", Vector(0.36, 0.34, 0.6), DARK)
		Fixture(Top(spot, 20) + forward * 18.5, cone, "SM_Cylinder", Vector(0.26, 0.26, 0.02), GREY)
		Fixture(Top(spot, 20) + forward * 19.5, cone, "SM_Cylinder", Vector(0.08, 0.08, 0.02), DARK)
		Fixture(Top(spot, 46) + forward * 18.5, cone, "SM_Cylinder", Vector(0.1, 0.1, 0.02), GREY)
	end,
}

-- A loose physics prop that never leaves a copy behind: refilling takes the old one away unless someone holds it
local function LooseSlot(location, rotation, asset, scale, reach)
	local current = nil
	Playground.Slot(function()
		if (current and current:IsValid() and not current:GetHandler()) then current:Destroy() end
		current = Prop(location, rotation, asset, CollisionType.Normal, true, GrabMode.Enabled)
		if (scale) then current:SetScale(scale) end
		return current
	end, reach or 1500)
end

-- Chickens peck around inside their pen on the grass (580 inside), walking to a new random point every few seconds
local CHICKENS = 5
local PEN_REACH = 220

local function SpawnChicken(spot, index)
	local start = Playground.At(spot, (index - 2) * 70, 0, 30)
	local chicken = DefaultCharacter("Chicken", start, Rotator(0, math.random(0, 359), 0), function(l, r) return CharacterSimple(l, r, "nanos-world::SK_Chicken", "nanos-world::ABP_Chicken") end)

	local function Wander()
		if (not chicken:IsValid() or chicken:GetHealth() <= 0) then return false end
		chicken:MoveTo(Playground.At(spot, math.random(-PEN_REACH, PEN_REACH), math.random(-PEN_REACH, PEN_REACH), spot.top), 20)
	end

	local timer = Timer.SetInterval(Wander, math.random(2500, 5000))
	Timer.Bind(timer, chicken)

	return chicken
end

-- Physics objects on the Prop pad: asset, x, y in the pad's axes, yaw
local PROPS = {
	{ "nanos-world::SM_PlasticBarrel_01", -70, -40, 0 },
	{ "nanos-world::SM_Guitar", 60, -50, 20 },
	{ "nanos-world::SM_Crate_Full_01", 0, 60, -15 },
}

-- The little shooting range by the pickables plaza: weapons lying on each table, like the range's armory
local RANGE_TABLES = {
	Entities_RangeTable1 = { "AP5", "P90", "M1911", "DesertEagle" },
	Entities_RangeTable2 = { "AR4", "Rem870", "AWP" },
}
local TABLE_LENGTH = 210

-- Loose things to play with around each picnic table on the grass: asset, x, y in the table's axes, scale; z above the grass, or on the table top
local PICNIC_PROPS = {
	{ "nanos-world::SM_Ball_VR", 180, 140, Vector(0.35, 0.35, 0.35), 25 },
	{ "nanos-world::SM_Ball_VR", -220, -60, Vector(0.35, 0.35, 0.35), 25 },
	{ "nanos-world::SM_Cone", 260, -160, Vector(0.5, 0.5, 0.5), 26 },
	{ "nanos-world::SM_Cone", 300, -40, Vector(0.5, 0.5, 0.5), 26 },
	{ "nanos-world::SM_Cone", 340, 80, Vector(0.5, 0.5, 0.5), 26 },
	{ "nanos-world::SM_Crate_07", -200, 180, nil, 2 },
	{ "nanos-world::SM_Fruit_Watermelon_01", -40, 0, nil, "table" },
	{ "nanos-world::SM_Fruit_Pineapple_01", 45, 10, nil, "table" },
}

-- Sounds the speaker plays, one per press in turn: short one-shots only (the car horns loop)
local SOUND_EFFECTS = { "nanos-world::A_Vehicle_Horn_Bike_01", "nanos-world::A_Robot_Beep_Whistle", "nanos-world::A_Fart", "nanos-world::A_Robot_Reaction", "nanos-world::A_Vehicle_Horn_Bike_02", "nanos-world::A_Robot_Sad" }

local TRIGGER_COLOR = Color(0.1, 1, 0.2)

-- The Dimension pad sends whoever steps on it to another dimension, where only what is spawned in it exists, and back to the first when they step off.
-- A trigger only sees actors in its own dimension, so there are two: one in the first to send them over, one in the other to bring them back
local DIMENSION = 2
local DIMENSION_COLOR = Color(0.6, 0.1, 1)
-- What only the other dimension holds: a few cones floating around the pad (x, y in the pad's axes, height) and a title over it
local DIMENSION_CONES = { { 110, 110, 60 }, { -110, 110, 120 }, { -110, -110, 60 }, { 110, -110, 120 } }

local function SendTo(character, dimension)
	if (not character:IsValid() or character:GetHealth() <= 0) then return end
	local player = character:GetPlayer()
	if (player and player:GetDimension() ~= dimension) then player:SetDimension(dimension) end
end

local function InDimension(entity)
	entity:SetDimension(DIMENSION)
	return Playground.Track(entity)
end

local function SpawnDimensionPad(pad)
	local location, rotation, extent = Top(pad, 100), Facing(pad), Vector(130, 130, 100)
	local enter = Playground.Track(Trigger(location, rotation, extent, TriggerType.Box, true, DIMENSION_COLOR, { "Character" }))
	local leave = InDimension(Trigger(location, rotation, extent, TriggerType.Box, false, DIMENSION_COLOR, { "Character" }))
	enter:Subscribe("BeginOverlap", function(self, entity) SendTo(entity, DIMENSION) end)
	leave:Subscribe("EndOverlap", function(self, entity) SendTo(entity, 1) end)

	InDimension(TextRender(Top(pad, 280), rotation, "DIMENSION " .. DIMENSION, 64, DIMENSION_COLOR))
	InDimension(Light(Top(pad, 220), Rotator(), DIMENSION_COLOR, LightType.Point, 40, 900, 44, 0, 10000, true, false))
	for k, cone in ipairs(DIMENSION_CONES) do
		local mesh = InDimension(StaticMesh(Playground.At(pad, cone[1], cone[2], pad.top + cone[3]), Rotator(0, k * 45, 0), "nanos-world::SM_Cone", CollisionType.NoCollision))
		mesh:SetScale(Vector(0.5, 0.5, 0.5))
		mesh:SetMaterialColorParameter("Tint", DIMENSION_COLOR)
	end
end

-- Someone dying over there comes back with their next life, or they could not possess a character spawned in the first dimension
Character.Subscribe("Death", function(character)
	local player = character:GetPlayer()
	if (player and player:GetDimension() == DIMENSION) then player:SetDimension(1) end
end)

-- The three lights, each switched on and off by the push button on the pedestal in front of it: the light last spawned for each, and its color
local LIGHTS = {}
local LIGHT_COLORS = { LightPoint = POINT_COLOR, LightSpot = SPOT_COLOR, LightRect = RECT_COLOR }
local light_on = { LightPoint = true, LightSpot = true, LightRect = true }

local function KeepLight(name, light)
	LIGHTS[name] = light
	light:SetVisibility(light_on[name])
	return light
end

-- A default-characters humanoid standing on its display, facing the plaza
local function OnDisplay(name, mesh)
	return function(spot)
		local character = DefaultCharacter(name, Top(spot, 95), Facing(spot), function(l, r) return Character(l, r, mesh) end)
		character:SetCanPunch(false)
		return character
	end
end

-- The pickables lie on the sandbox's tool tables (entities.py "table", widened along their local X): on their side along the table, muzzle towards -X,
-- the middle of the gun's mesh on the middle of the table. Per gun, the centre of its mesh's bounds from its pivot and its half thickness lying down
-- (the bounds' Y, which a 90 roll turns upright): SK_AK47, SK_Glock, SK_Moss500, SK_P90
local GUN_SHAPES = {
	AK47 = { centre = Vector(17.89, 1.16, 0.52), half = 3.33 },
	Glock = { centre = Vector(5.68, -0.07, 2.09), half = 1.67 },
	Moss500 = { centre = Vector(33.09, -0.03, 2.15), half = 1.98 },
	P90 = { centre = Vector(-3.86, 0, 5.36), half = 2.85 },
}

local function OnTable(spot, name)
	local shape = GUN_SHAPES[name]
	local rotation = Rotator(0, spot.rotation.Yaw + 180, 90)
	return Top(spot, shape.half + 0.5) - rotation:RotateVector(shape.centre), rotation
end

-- A melee lying along its table, centred on it, its handle towards the table's +X
local function MeleeOnTable(spot, shape, spawn)
	local location, rotation = Playground.LyingMelee(shape, Top(spot, 0), spot.rotation.Yaw - 90)
	return spawn(location, rotation)
end

-- How long the Particle Burst button waits after a press before it takes another (ms), so the explosion plays out first
local BURST_COOLDOWN = 3000

local EXHIBITS = {
	CharacterAdventure = OnDisplay("AdventureMaleA", "nanos-world::SK_Adventure_02_Full_03"),
	HumanSkeleton = OnDisplay("HumanSkeleton", "nanos-world::SK_HumanSkeleton"),
	-- Lifted by their capsule's half height
	CharacterSimple = function(spot)
		return DefaultCharacter("StackOBot", Top(spot, 60), Facing(spot), function(l, r) return CharacterSimple(l, r, "nanos-world::SK_StackOBot", "nanos-world::ABP_StackOBot") end)
	end,
	CharacterSimpleGoat = function(spot)
		return DefaultCharacter("Goat", Top(spot, 57), Facing(spot), function(l, r) return CharacterSimple(l, r, "nanos-world::SK_Goat", "nanos-world::ABP_Goat") end)
	end,
	-- A plain native Character, not default-characters' NPC (which stands itself back up after a ragdoll)
	Ragdoll = function(spot)
		local character = Character(Top(spot, 95), Facing(spot), "nanos-world::SK_Mannequin")
		character:SetRagdollMode(true)
		return character
	end,
	-- Goes round the corners of its square pad on the grass, one after the other (needs the level's NavMesh)
	AIWalker = function(spot)
		local corner = 250
		local corners = {
			Playground.At(spot, corner, corner, spot.top), Playground.At(spot, corner, -corner, spot.top),
			Playground.At(spot, -corner, -corner, spot.top), Playground.At(spot, -corner, corner, spot.top),
		}
		local character = DefaultCharacter("MannequinFemale", corners[4] + Vector(0, 0, 95), Facing(spot), function(l, r) return Character(l, r, "nanos-world::SK_Mannequin_Female") end)
		local next_corner = 1
		character:MoveTo(corners[next_corner], 30)
		character:Subscribe("MoveComplete", function(self)
			next_corner = next_corner % #corners + 1
			self:MoveTo(corners[next_corner], 30)
		end)
		return character
	end,
	Weapon = function(spot)
		return NanosWorldWeapons and NanosWorldWeapons.AK47(OnTable(spot, "AK47"))
	end,
	Pistol = function(spot)
		return NanosWorldWeapons and NanosWorldWeapons.Glock(OnTable(spot, "Glock"))
	end,
	Shotgun = function(spot)
		return NanosWorldWeapons and NanosWorldWeapons.Moss500(OnTable(spot, "Moss500"))
	end,
	SMG = function(spot)
		return NanosWorldWeapons and NanosWorldWeapons.P90(OnTable(spot, "P90"))
	end,
	Crowbar = function(spot)
		return MeleeOnTable(spot, "Crowbar", function(l, r)
			if (NanosWorldWeapons and NanosWorldWeapons.Crowbar) then return NanosWorldWeapons.Crowbar(l, r) end
			return Melee(l, r, "nanos-world::SM_Crowbar_01", CollisionType.Auto, true, HandlingMode.SingleHandedMelee)
		end)
	end,
	Grenade = function(spot)
		return Grenade(Top(spot, 8), Rotator())
	end,
	-- A freight container on the grass that nothing can move: no physics at all
	StaticMesh = function(spot)
		return StaticMesh(spot.location, Facing(spot), "nanos-world::SM_FreightContainer")
	end,
	-- The vegetable field: every plant on the soil ridges (entities.py FIELD, 7 rows 1000 apart end to end) is one instance of a single draw call, cabbages or, while Halloween is on, pumpkins
	InstancedStaticMesh = function(spot)
		local transforms = {}
		local rows, row_span, length, per_row = 7, 1000, 760, 9
		-- Sat into the top of the ridges: SM_PG_SoilRow is 18 tall, standing on the soil
		local ridge = 15
		-- Pumpkins (SM_Pumpkin_Carved_03, the plain one, 20 across with its pivot at the bottom) are solid, the cabbages (SM_Veg_Cabbage_01, 24 across with its pivot in the middle) lifted onto the ridge a little sunk and walked through, both scaled up
		local is_halloween = Playground.theme == "halloween"
		local plant = is_halloween and "nanos-world::SM_Pumpkin_Carved_03" or "nanos-world::SM_Veg_Cabbage_01"
		local scale = is_halloween and 1.5 or 1.6
		local lift = is_halloween and 0 or 9
		for r = 0, rows - 1 do
			for k = 0, per_row - 1 do
				local size = (0.9 + ((r * 7 + k * 3) % 5) * 0.06) * scale
				transforms[#transforms + 1] = {
					Location = Vector(-length / 2 + k * length / (per_row - 1) + ((r + k) % 3 - 1) * 6, -row_span / 2 + r * row_span / (rows - 1), ridge + lift * size),
					Rotation = Rotator(0, ((r + k) % 2) * 180 + ((r * 53 + k * 97) % 25 - 12), 0),
					Scale = Vector(size, size, size),
				}
			end
		end
		return InstancedStaticMesh(Top(spot, 0), spot.rotation, plant, is_halloween and CollisionType.Normal or CollisionType.NoCollision, transforms)
	end,
	Particle = function(spot)
		return Particle(Top(spot, 20), Rotator(), "nanos-world::P_Fire", false, true)
	end,
	-- A push button on its pedestal: each press bursts a particle over the ring on the floor behind it (entities.py "Entities_ParticleBurstAt")
	ParticleBurst = function(spot)
		if (not Playground.HasSandbox()) then return nil end
		local at = Playground.Spot("Entities_ParticleBurstAt")
		local location = at and at.location + Vector(0, 0, 120) or Top(spot, 170)
		return Playground.Button(Top(spot, 0), Facing(spot), "burst", "burst", function()
			-- A one-shot explosion (its emitters play once), destroyed by itself when it ends
			Particle(location, Rotator(), "nanos-world::P_Explode_01", true, true)
		end, nil, false, "PushButton", false, nil, BURST_COOLDOWN)
	end,
	-- A push button on the pedestal beside the speaker: each press plays the next sound effect from it (the Sound itself is spawned on the clients)
	Sound = function(spot)
		local played = 0
		local button = Playground.Spot("Entities_SoundButton")
		if (not button or not Playground.HasSandbox()) then return nil end
		return Playground.Button(Top(button, 0), Facing(button), "play sound", "play sound", function()
			played = played % #SOUND_EFFECTS + 1
			Playground.PlaySound(Top(spot, 30), SOUND_EFFECTS[played])
		end, nil, false, "PushButton")
	end,
	TextRender = function(spot)
		return TextRender(Top(spot, 60), Facing(spot), "Hello!", 48, Color.WHITE)
	end,
	-- Extruded and centred on its column at the TextRender's height, standing like a statue (not turning to the camera); it reads towards its -X, so it is turned around
	Text3D = function(spot)
		local text = Text3D(Top(spot, 60), Rotator(0, spot.rotation.Yaw + 180, 0), "nanos\nworld", Vector(1, 1, 1), PURPLE, FontType.Roboto, Text3DAlignCamera.Unaligned)
		text:SetGlyphSettings(20, 2, Text3DBevelType.Convex, 4, false)
		text:SetTextSettings(0, -30, 0, Text3DHorizontalAlignment.Center, Text3DVerticalAlignment.Center)
		-- A regular lit material instead of the default glowing one
		text:SetMaterial(LIT)
		text:SetMaterialColorParameter("Tint", PURPLE)
		text:SetMaterialColorParameter("Emissive", Color.BLACK)
		text:SetMaterialScalarParameter("Roughness", 0.9)
		text:SetMaterialScalarParameter("Specular", 0.2)
		return text
	end,
	-- No shadows: each light sits inside its own fixture
	LightPoint = function(spot)
		return KeepLight("LightPoint", Light(Top(spot, 60), Rotator(), POINT_COLOR, LightType.Point, 8, 600, 44, 0, 10000, true, false))
	end,
	LightSpot = function(spot)
		return KeepLight("LightSpot", Light(Top(spot, 199), Rotator(-90, 0, 0), SPOT_COLOR, LightType.Spot, 15, 800, 35, 0, 10000, true, false))
	end,
	LightRect = function(spot)
		return KeepLight("LightRect", Light(Top(spot, 120) + Facing(spot):GetForwardVector(), Facing(spot), RECT_COLOR, LightType.Rect, 8, 600, 44, 0, 10000, true, false))
	end,
	-- Same footprint and turn as the pad under it (2.6 m square); a lamp behind it turns green while anyone stands inside
	-- Server triggers test each actor's origin, a character's capsule centre about 90 above its feet: the box reaches 200 up
	Trigger = function(spot)
		local trigger = Trigger(Top(spot, 100), Facing(spot), Vector(130, 130, 100), TriggerType.Box, true, PURPLE, { "Character" })
		local behind = Playground.At(spot, -160, 0, spot.top)
		Fixture(behind + Vector(0, 0, 80), Rotator(), "SM_Cylinder", Vector(0.05, 0.05, 1.6), DARK)
		local bulb = Fixture(behind + Vector(0, 0, 170), Rotator(), "SM_Sphere", Vector(0.22, 0.22, 0.22), GREY)
		local light = Playground.Track(Light(behind + Vector(0, 0, 170), Rotator(), TRIGGER_COLOR, LightType.Point, 30, 500, 44, 0, 10000, true, false))
		light:SetVisibility(false)
		local inside = 0
		-- The globe glows in the light's own color while it is on
		local function Lit()
			light:SetVisibility(inside > 0)
			bulb:SetMaterialColorParameter("Tint", inside > 0 and TRIGGER_COLOR or GREY)
			bulb:SetMaterialColorParameter("Emissive", inside > 0 and Glow(TRIGGER_COLOR) or Color.BLACK)
		end
		trigger:Subscribe("BeginOverlap", function(self, entity)
			inside = inside + 1
			Lit()
		end)
		trigger:Subscribe("EndOverlap", function(self, entity)
			inside = math.max(0, inside - 1)
			Lit()
		end)
		return trigger
	end,
	-- Two balls on the pad joined by a cable that holds them at most CABLE_LENGTH apart: grab one and drag the other along
	Cable = function(spot)
		local length = 400
		local balls = {}
		for k, side in ipairs({ -1, 1 }) do
			local ball = Playground.Track(Prop(Playground.At(spot, 0, side * 140, spot.top + 30), Rotator(), "nanos-world::SM_Ball_VR", CollisionType.Normal, true, GrabMode.Enabled))
			ball:SetScale(Vector(0.4, 0.4, 0.4))
			balls[k] = ball
		end
		local cable = Playground.Track(Cable(Playground.At(spot, 0, 0, spot.top + 30), true))
		cable:SetLinearLimits(ConstraintMotion.Limited, ConstraintMotion.Limited, ConstraintMotion.Limited, length, 0, true, 10000, 100)
		cable:SetCableSettings(length * 0.7, 16, 2)
		cable:SetRenderingSettings(4, 4, 1)
		-- On each ball's surface (SM_Ball_VR radius 70, in its unscaled space)
		cable:AttachStartTo(balls[1], Vector(0, 70, 0))
		cable:AttachEndTo(balls[2], Vector(0, -70, 0))
		-- The set goes and comes back together
		balls[1]:Subscribe("Destroy", function()
			if (cable:IsValid()) then cable:Destroy() end
			if (balls[2]:IsValid()) then balls[2]:Destroy() end
		end)
		return balls[1]
	end,
}

-- Exhibit spot names come from the class labels ("Light (Point)" -> "LightPoint")
Playground.Setup("Entities", function()
	for name, spawn in pairs(EXHIBITS) do
		local spot = Playground.Spot("Entities_" .. name)

		if (spot) then
			Playground.Slot(function() return spawn(spot) end, 600)
		end
	end

	if (NanosWorldWeapons) then
		for table_name, weapons in pairs(RANGE_TABLES) do
			local spot = Playground.Spot(table_name)
			if (spot) then
				local step = TABLE_LENGTH / #weapons
				for i, name in ipairs(weapons) do
					local class = NanosWorldWeapons[name]
					if (class) then
						-- Lying on their side along the table (its local X), grips towards the visitor at the front (local +Y), muzzles to the targets
						local location = Playground.At(spot, (i - (#weapons + 1) / 2) * step, 15, spot.top + 6)
						local rotation = Rotator(0, spot.rotation.Yaw - 90, 90)
						Playground.ReturningSlot(function() return class(location, rotation) end, 400)
					end
				end
			end
		end
	end

	for _, entry in ipairs(Playground.SpotsWith("Entities_Picnic")) do
		local spot = entry.spot
		for k, item in ipairs(PICNIC_PROPS) do
			local z = item[5] == "table" and spot.top + 2 or item[5]
			LooseSlot(Playground.At(spot, item[2], item[3], z), Rotator(0, spot.rotation.Yaw + k * 40, 0), item[1], item[4])
		end
	end

	-- Several props share the Prop pad, each refilled on its own
	local pad = Playground.Spot("Entities_Prop")
	if (pad) then
		for _, entry in ipairs(PROPS) do
			local location = Playground.At(pad, entry[2], entry[3], pad.top + 2)
			Playground.Slot(function() return Prop(location, Rotator(0, pad.rotation.Yaw + entry[4], 0), entry[1], CollisionType.Normal, true, GrabMode.Enabled) end, 1500)
		end
	end

	for name, build in pairs(FIXTURES) do
		local spot = Playground.Spot("Entities_" .. name)
		local glow = spot and build(spot)
		local button = Playground.Spot("Entities_" .. name .. "Button")

		-- Each press turns the light and its fixture's glow off or back on
		if (glow and button and LIGHT_COLORS[name] and Playground.HasSandbox()) then
			local function Switch(is_on)
				light_on[name] = is_on
				if (LIGHTS[name] and LIGHTS[name]:IsValid()) then LIGHTS[name]:SetVisibility(is_on) end
				if (glow:IsValid()) then SetGlow(glow, LIGHT_COLORS[name], is_on) end
			end
			Playground.Button(Top(button, 0), Facing(button), "turn on", "turn off", function() Switch(true) end, function() Switch(false) end, true, "PushButton", light_on[name])
		end
	end

	local dimension_pad = Playground.Spot("Entities_Dimension")
	if (dimension_pad) then SpawnDimensionPad(dimension_pad) end

	local pen = Playground.Spot("Entities_Chickens")
	if (pen) then
		for i = 1, CHICKENS do
			Playground.Slot(function() return SpawnChicken(pen, i) end, 1500)
		end
	end
end)
