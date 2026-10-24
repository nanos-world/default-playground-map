-- Every informative text of the playground, drawn with TextRender on the level's boards and stands
-- Keyed by spot name, so moving a stand in the level moves its text with it
-- Info stands outside the museum carry their text in the level itself (spot.info, set by the generators), the museum's are below

local INK = Color(0, 0, 0)
local PURPLE = Color(0.35, 0.1, 0.8)

-- Museum info stands, one per native entity exhibit: title and a few short lines
local EXHIBIT_INFO = {
	-- One stand for the two humans behind it, one for the robot and the goat
	Character = { "Character", "The full humanoid pawn: walks,\ndrives, shoots, ragdolls. Any\nmesh works, even bare bones." },
	Chickens = { "Chickens", "CharacterSimple with the\nchicken mesh and its own\nanimation blueprint." },
	CharacterSimple = { "CharacterSimple", "A lightweight pawn for\nrobots, animals and NPCs,\nwith any mesh and anim." },
	Ragdoll = { "Ragdoll", "Character:SetRagdollMode(true)\nhands the body to physics.\nPush it, shoot it." },
	AIWalker = { "AI Walker", "Character:MoveTo walks a pawn\nalong the NavMesh. This one\ngoes round the square." },
	Weapon = { "Weapon", "Pick it up, aim and shoot.\nAmmo, recoil, sights and\nsounds are all scriptable." },
	Pistol = { "Pistol", "A Weapon held in one hand.\nSame class, other mesh,\nhandling and sounds." },
	Shotgun = { "Shotgun", "A Weapon firing many\nbullets per shot, with\nits own spread." },
	SMG = { "SMG", "A Weapon with a high\ncadence and a big magazine,\nlike this P90." },
	Crowbar = { "Melee", "Grab it and swing it with\nthe mouse. Any mesh can\nbecome a melee weapon." },
	ShootingRange = { "Shooting Range", "Grab a weapon and shoot\nthe targets: they fall and\nstand up again." },
	Grenade = { "Grenade", "Pull the pin and throw.\nTimer, bounce and explosion\neffect are configurable." },
	Prop = { "Prop", "A physics object.\nGrab it, throw it, weld it\nwith the sandbox tools." },
	StaticMesh = { "StaticMesh", "Any mesh, no physics:\nthis container never moves.\nCheap scripted scenery." },
	InstancedStaticMesh = { "InstancedStaticMesh", "This whole field of crops\nis one entity: many copies\nof a mesh, one draw call." },
	Cable = { "Cable", "A rope between two actors.\nGrab a ball and drag it,\nthe other one follows." },
	Gizmo = { "Gizmo", "Move, rotate and scale\nobjects at runtime with\nthe familiar editor handles." },
	Decal = { "Decal", "A material projected onto\nwhatever is below it:\nmarks, splats, logos." },
	Particle = { "Particle", "Niagara effects: fire,\nsmoke, sparks, explosions,\nfrom the asset packs." },
	ParticleBurst = { "Particle Burst", "A short Particle spawned\non demand, then removed." },
	Billboard = { "Billboard", "A flat image that always\nturns to face the camera.\nClient only." },
	TextRender = { "TextRender", "Flat text in the world,\nlike this very stand.\nCheap and readable." },
	Text3D = { "Text3D", "Real 3D letters with depth,\nbevel and lighting.\nFor titles and signs." },
	LightPoint = { "Light (Point)", "Shines in every direction\nlike a bare light bulb." },
	LightSpot = { "Light (Spot)", "A cone of light, like a\nstage spot or a torch." },
	LightRect = { "Light (Rect)", "Light from a rectangle,\nlike a softbox window." },
	Sound = { "Sound", "3D sound with distance\nfalloff, client only." },
	Trigger = { "Trigger", "An invisible volume that\nfires events when things\nenter it. Step in, see the lamp." },
	Dimension = { "Dimension", "Players only see what is in\ntheir dimension. Step on the\npad to visit dimension 2." },
	Jukebox = { "Jukebox", "Music from a Sound that\nloops. Song, volume and\nrange in its context menu." },
	WebUI = { "WebUI", "A web page (HTML, CSS, JS)\nrendered on a mesh with\nSetMaterialFromWebUI." },
	Widget3D = { "Widget3D", "An Unreal UMG widget\nplaced in the world as\na 3D panel." },
	SceneCapture = { "SceneCapture", "A camera rendering into a\ntexture: security cams,\nmirrors, live screens." },
}

-- Intro boards outside the hub doors of the zones that need one (hub.py INTRO_SKIP has none)
local ZONE_INTRO = {
	Sandbox = { "SANDBOX & PHYSICS", "Entities, the physics gun,\nevery tool gun and props.\nOpen the context menu (C)\nand click things to explore more options" },
	Entities = { "NATIVE ENTITIES", "A museum of every class\nthe scripting API spawns,\neach one live, with a stand" },
}

-- The hub's welcome board: what nanos world and this map are on the left, the controls on the right
local WELCOME_TITLE = "WELCOME TO NANOS WORLD"
local WELCOME_ABOUT = "nanos world is a multiplayer sandbox where\nanything can be made with Lua scripting:\ngame modes, maps, vehicles, weapons...\n\nIt is still in development, so expect\nrough edges and new features often.\n\nThis is the Playground, a tour of what\nthe game offers out of the box. Walk\nthrough the coloured doors to try weapons,\nvehicles, physics, the sandbox tools\nand every native entity."

-- Controls listed on the welcome board: label, key binding, and the key shown if the binding is not found (a Sandbox binding without one is left out)
local WELCOME_CONTROLS = {
	{ "Move", nil, "WASD" },
	{ "Jump", "Jump", "Space" },
	{ "Sprint", "Sprint", "Shift" },
	{ "Crouch", "Crouch", "C" },
	{ "Interact / Pick Up", "Interact", "E" },
	{ "Drop", "Drop", "G" },
	{ "Reload", "Reload", "R" },
	{ "Punch", "Punch", "Left Click" },
	{ "Chat", "Chat", "T" },
	{ "Spawn menu", "SpawnMenu" },
	{ "Context menu", "ContextMenu" },
	{ "Undo last spawn", "Undo" },
	{ "No clip", "NoClip" },
	{ "Ragdoll", "Ragdoll" },
}

-- Readable names for the keys Input reports
local KEY_NAMES = { SpaceBar = "Space", LeftShift = "Shift", LeftControl = "Ctrl", LeftAlt = "Alt", LeftMouseButton = "Left click", RightMouseButton = "Right click", MiddleMouseButton = "Middle click" }

local function WelcomeControls()
	local lines = { "CONTROLS" }
	for _, control in ipairs(WELCOME_CONTROLS) do
		local label, binding, fallback = control[1], control[2], control[3]
		local key = binding and Input.GetMappedKeys(binding)[1] or nil
		key = key and (KEY_NAMES[key] or key) or fallback
		if (key) then lines[#lines + 1] = label .. ": " .. key end
	end
	return table.concat(lines, "\n")
end

local spawned = {}

local function Text(location, rotation, text, size, color)
	-- Black text is unlit, or the sun washes the letters out on the bright panels and they reflect like the paper
	-- Coloured text (titles) is lit instead: an unlit colour is emissive and glows at night
	-- The material reads the colour as sRGB bytes back as linear, which lifts it (0.05 shows as 0.25 grey): pre-darken it so it shows as given
	local shown = Color(color.R ^ 2.2, color.G ^ 2.2, color.B ^ 2.2)
	local is_black = color.R + color.G + color.B == 0
	local entity = TextRender(location, rotation, text, size, shown, is_black and TextRenderRenderingType.Unlit or TextRenderRenderingType.Lit)
	spawned[#spawned + 1] = entity
	return entity
end

-- Placeholder Board: panel 400 x 300 from z 60, front face at local +Y 15 (all scaled by the spot)
-- With a second body, the two share the panel as columns (the visitor's left is local -X)
-- A title's capitals run about this wide per letter, in parts of its size; a long one shrinks to the panel's width less a margin
local BOARD_LETTER_W = 0.62
local BOARD_TITLE_W = 360

local function BoardText(spot, title, body, title_size, body_size, body_right)
	local s = spot.scale
	local front = Rotator(0, Playground.FrontYaw(spot), 0)
	local top = (60 + 300) * s.Z
	local column = body_right and 100 * s.X or 0
	local size = title_size * s.Z
	size = math.min(size, BOARD_TITLE_W * s.X / (#title * BOARD_LETTER_W))
	Text(Playground.At(spot, 0, 15 * s.Y + 1, top - 55 * s.Z), front, title, size, INK)
	Text(Playground.At(spot, -column, 15 * s.Y + 1, top - 185 * s.Z), front, body, body_size * s.Z, INK)
	if (body_right) then
		Text(Playground.At(spot, column, 15 * s.Y + 1, top - 185 * s.Z), front, body_right, body_size * s.Z, INK)
	end
end

local INFO_TITLE_FIT = 15
-- A title keeps its zone's hue but no channel above this, or a light one (yellow, orange) can't be read on the white panel
local INFO_TITLE_MAX = 0.4

local function Darkened(color)
	local k = math.min(1, INFO_TITLE_MAX / math.max(color.R, color.G, color.B, 0.001))
	return Color(color.R * k, color.G * k, color.B * k)
end

local function InfoText(spot, title, body, color)
	-- Stands, plates and table signs share the leaning panel, a wall plate's stands upright
	local tilt, face = INFO_TILT, INFO_FACE
	if (spot.mesh == "WallPlate") then tilt, face = 0, WALL_PLATE_FACE end
	local rotation = Rotator(tilt, Playground.FrontYaw(spot), 0)
	local up = Vector(0, -math.sin(math.rad(tilt)), math.cos(math.rad(tilt)))
	-- Lifted off the panel along its normal, or the letters sink into the surface
	local normal = Vector(0, math.cos(math.rad(tilt)), math.sin(math.rad(tilt)))
	-- Stands are scaled uniformly (the small ones in front of the tool tables), the text scales with them
	local s = spot.scale
	local k = math.min(s.X, s.Z)
	local function Scaled(v) return Vector(v.X * s.X, v.Y * s.Y, v.Z * s.Z) end
	if (not body or body == "") then
		-- A title alone (a stall's board): centred, as tall as half the panel and no wider than it (72 x 48 unscaled)
		local at = Scaled(face + normal * 1.5)
		local size = math.min(24 * s.Z, 72 * s.X * 0.85 / (0.62 * #title))
		Text(Playground.At(spot, at.X, at.Y, at.Z), rotation, title, size, Darkened(color or PURPLE))
		return
	end
	local title_at, body_at = Scaled(face + normal * 1.5 + up * 12), Scaled(face + normal * 1.5 - up * 6)
	-- Long titles shrink to the width of about INFO_TITLE_FIT letters at full size, so they stay on the panel
	local fit = math.min(1, INFO_TITLE_FIT / #title)
	Text(Playground.At(spot, title_at.X, title_at.Y, title_at.Z), rotation, title, 8.5 * k * fit, Darkened(color or PURPLE))
	Text(Playground.At(spot, body_at.X, body_at.Y, body_at.Z), rotation, body, 5.5 * k, INK)
end

local function SpawnTexts()
	for name, info in pairs(EXHIBIT_INFO) do
		local spot = Playground.Spot("Entities_" .. name .. "_Info")
		if (spot) then InfoText(spot, info[1], info[2], spot.color) end
	end

	for _, spot in pairs(SPOTS) do
		if (spot.info) then InfoText(spot, spot.info.title, spot.info.body, spot.color) end
	end

	for zone, info in pairs(ZONE_INTRO) do
		local spot = Playground.Spot("Hub_Intro_" .. zone)
		if (spot) then BoardText(spot, info[1], info[2], 48, 26) end
	end

	local welcome = Playground.Spot("Hub_Board_Welcome")
	if (welcome) then BoardText(welcome, WELCOME_TITLE, WELCOME_ABOUT, 36, 13, WelcomeControls()) end

	local panel = Playground.Spot("Hub_SkyPanel")
	if (panel) then
		local front = Rotator(0, Playground.FrontYaw(panel), 0)
		Text(Playground.At(panel, 0, 6, 172), front, "TIME & WEATHER", 16, INK)
		for _, button in ipairs(SKY_BUTTONS) do
			Text(Playground.SkyButtonLocation(panel, button) + front:RotateVector(Vector(1, 0, 0)) - Vector(0, 0, 32), front, button.label, 9, INK)
		end
	end
end

Package.Subscribe("Load", SpawnTexts)

Package.Subscribe("Unload", function()
	for _, entity in ipairs(spawned) do
		if (entity:IsValid()) then entity:Destroy() end
	end
	spawned = {}
end)
