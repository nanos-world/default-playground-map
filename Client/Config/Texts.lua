-- Museum info stands, one per native entity exhibit ("Entities_<name>_Info"): title and a few short lines
EXHIBIT_INFO = {
	-- One stand for the two humans behind it, one for the robot and the goat
	Character = {
		title = "Character",
		body = "The full humanoid pawn: walks,\ndrives, shoots, interacts.\nUE4 Skeleton only."
	},
	Chickens = {
		title = "Chickens",
		body = "CharacterSimple with the\nchicken mesh and its own\nanimation blueprint."
	},
	CharacterSimple = {
		title = "CharacterSimple",
		body = "A lightweight pawn for\nrobots, animals and NPCs,\nwith any mesh and anim."
	},
	Ragdoll = {
		title = "Ragdoll",
		body = "Character:SetRagdollMode(true)\nhands the body to physics."
	},
	AIWalker = {
		title = "AI Walker",
		body = "Character:MoveTo walks a pawn\nalong the NavMesh. This one\ngoes round the square."
	},
	Weapon = {
		title = "Weapon",
		body = "Pick it up, aim and shoot.\nAmmo, recoil, sights and\nsounds are all scriptable."
	},
	Pistol = {
		title = "Pistol",
		body = "A Weapon held in one hand.\nSame class, other mesh,\nhandling and sounds."
	},
	Shotgun = {
		title = "Shotgun",
		body = "A Weapon firing many\nbullets per shot, with\nits own spread."
	},
	SMG = {
		title = "SMG",
		body = "A Weapon with a\nred dot attached."
	},
	Crowbar = {
		title = "Melee",
		body = "Grab it and attack it with\nleft click. Any static mesh can\nbecome a melee weapon."
	},
	ShootingRange = {
		title = "Shooting Range",
		body = "Grab a weapon and shoot\nthe targets: they fall and\nstand up again."
	},
	Grenade = {
		title = "Grenade",
		body = "Pull the pin and throw.\nTimer, bounce and explosion\neffect are configurable."
	},
	Prop = {
		title = "Prop",
		body = "A physics object.\nGrab it, throw it, weld it\nwith the sandbox tools."
	},
	StaticMesh = {
		title = "StaticMesh",
		body = "Any mesh, no physics:\nthis container never moves.\nCheap scripted scenery."
	},
	InstancedStaticMesh = {
		title = "InstancedStaticMesh",
		body = "This whole field of crops\nis one entity: many copies\nof a mesh, one draw call."
	},
	Cable = {
		title = "Cable",
		body = "A rope between two actors.\nGrab a ball and drag it,\nthe other one follows."
	},
	Gizmo = {
		title = "Gizmo",
		body = "Move, rotate and scale\nobjects at runtime with\nthe familiar editor handles.\nTry it in Context Menu (C)."
	},
	Decal = {
		title = "Decal",
		body = "A material projected onto\nwhatever is below it:\nmarks, splats, logos."
	},
	Particle = {
		title = "Particle",
		body = "Niagara effects: fire,\nsmoke, sparks, explosions,\nfrom the asset packs."
	},
	ParticleBurst = {
		title = "Particle Burst",
		body = "A short Particle spawned\non demand, then removed."
	},
	Billboard = {
		title = "Billboard",
		body = "A flat image that always\nturns to face the camera.\nClient only."
	},
	TextRender = {
		title = "TextRender",
		body = "Flat text in the world,\nlike this very stand.\nCheap and readable."
	},
	Text3D = {
		title = "Text3D",
		body = "Real 3D letters with depth,\nbevel and lighting.\nFor titles and signs."
	},
	LightPoint = {
		title = "Light (Point)",
		body = "Shines in every direction\nlike a bare light bulb."
	},
	LightSpot = {
		title = "Light (Spot)",
		body = "A cone of light, like a\nstage spot or a torch."
	},
	LightRect = {
		title = "Light (Rect)",
		body = "Light from a rectangle,\nlike a softbox window."
	},
	Sound = {
		title = "Sound (SFX)",
		body = "3D sound with distance\nfalloff, client only."
	},
	Trigger = {
		title = "Trigger",
		body = "An invisible volume that\nfires events when things\nenter it. Step in, see the lamp."
	},
	Dimension = {
		title = "Dimension",
		body = "Players only see what is in\ntheir dimension. Step on the\npad to visit dimension 2."
	},
	Jukebox = {
		title = "Sound (Music)",
		body = "Music from a Sound that\nloops. Song, volume and\nrange in its context menu."
	},
	WebUI = {
		title = "WebUI",
		body = "A web page (HTML, CSS, JS)\nrendered on a mesh with\nSetMaterialFromWebUI."
	},
	Widget3D = {
		title = "Widget3D",
		body = "An Unreal UMG widget\nplaced in the world as\na 3D panel."
	},
	SceneCapture = {
		title = "SceneCapture",
		body = "A camera rendering into a\ntexture: security cams,\nmirrors, live screens."
	}
}

-- Intro boards outside the hub doors ("Hub_Intro_<zone>") of the zones that need one (hub.py INTRO_SKIP has none)
ZONE_INTRO = {
	Sandbox = {
		title = "SANDBOX & PHYSICS",
		body = "Sandbox entities, the Physics Gun, \nTool Guns, Props and Contraptions\n\nOpen the context menu (C)\nand click things to explore more\noptions and customize the entities"
	},
	Entities = {
		title = "NATIVE ENTITIES",
		body = "A tour of every native scripting class\nnanos world has, from Characters\nto Lights, from Props to Particles\n\nRead the exhibits to see how they\nwork and their features and options"
	}
}

-- The hub's welcome board: what nanos world and this map are on the left, the controls on the right
WELCOME_TITLE = "WELCOME TO NANOS WORLD"
WELCOME_ABOUT = "nanos world is a multiplayer sandbox where\nanything can be made with Lua scripting:\ngame modes, maps, vehicles, weapons...\n\nIt is still in development, so expect\nrough edges and new features often.\n\nThis is the Playground, a tour of what\nthe game offers out of the box. Walk\nthrough the coloured doors to try weapons,\nvehicles, physics, the sandbox tools\nand every native entity."

-- Controls listed on the welcome board: their key binding, and the key shown if the binding is not found (a Sandbox binding without one is left out)
WELCOME_CONTROLS = {
	{
		label = "Move",
		fallback = "WASD"
	},
	{
		label = "Jump",
		binding = "Jump",
		fallback = "Space"
	},
	{
		label = "Sprint",
		binding = "Sprint",
		fallback = "Shift"
	},
	{
		label = "Crouch",
		binding = "Crouch",
		fallback = "C"
	},
	{
		label = "Interact / Pick Up",
		binding = "Interact",
		fallback = "E"
	},
	{
		label = "Drop",
		binding = "Drop",
		fallback = "G"
	},
	{
		label = "Reload",
		binding = "Reload",
		fallback = "R"
	},
	{
		label = "Punch",
		binding = "Punch",
		fallback = "Left Click"
	},
	{
		label = "Chat",
		binding = "Chat",
		fallback = "T"
	},
	{
		label = "Spawn menu",
		binding = "SpawnMenu"
	},
	{
		label = "Context menu",
		binding = "ContextMenu"
	},
	{
		label = "Undo last spawn",
		binding = "Undo"
	},
	{
		label = "No clip",
		binding = "NoClip"
	},
	{
		label = "Ragdoll",
		binding = "Ragdoll"
	}
}

-- Readable names for the keys Input reports
KEY_NAMES = {
	SpaceBar = "Space",
	LeftShift = "Shift",
	LeftControl = "Ctrl",
	LeftAlt = "Alt",
	LeftMouseButton = "Left click",
	RightMouseButton = "Right click",
	MiddleMouseButton = "Middle click"
}
