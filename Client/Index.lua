-- Playground map, client side: the exhibits whose classes only exist on the client

Package.Require("Texts.lua")
Package.Require("Halloween.lua")

local OnPedestal = Playground.Top

-- The screens hang on the gallery walls like paintings (entities.py SCREEN_CANVAS): a 320 x 190 canvas from z 80 to 270, the spot on the wall face, local +Y out of it
local SCREEN_W, SCREEN_H, SCREEN_Z = 320, 190, 175

local function ScreenCenter(spot, forward)
	return Playground.At(spot, 0, forward or 6, SCREEN_Z)
end

-- The screen materials are glossy by default: matte, like a real display, so the room's lights do not glare on them
local function Matte(plane)
	plane:SetMaterialScalarParameter("Specular", 0.1)
	plane:SetMaterialScalarParameter("Roughness", 1)
end

-- A plane covering the screen's front face (SM_Plane is 100 x 100 facing +Z, rolled to face local +Y)
local function ScreenPlane(spot)
	local plane = StaticMesh(ScreenCenter(spot), Rotator(0, spot.rotation.Yaw, 90), "nanos-world::SM_Plane", CollisionType.NoCollision)
	plane:SetScale(Vector(SCREEN_W / 100, SCREEN_H / 100, 1))
	return plane
end

-- Render targets in the screen's proportions, this many pixels per cm
local SCREEN_RES = 3
-- Widget3D draws this many pixels per cm and is scaled back down, so its text sits small on the canvas
local WIDGET_RES = 2.5

local spawned = {}

-- How close the local character must be for the gizmo exhibit to show its handles
local GIZMO_RANGE = 1500

local function Keep(entity)
	spawned[#spawned + 1] = entity
	return entity
end

local CLIENT_EXHIBITS = {
	Billboard = function(spot)
		return Billboard(OnPedestal(spot, 80), "nanos-world::M_NanosBillboardError", Vector2D(80, 80), false)
	end,
	-- A blood splat projected straight down onto the pad: a Decal already points down at Rotator() (ADecalActor's root carries a -90 pitch
	-- that multiplies with the spawn rotation), so only its yaw is set
	Decal = function(spot)
		return Decal(Playground.Top(spot, 0), Rotator(0, spot.rotation.Yaw + 180, 0), "nanos-world::MI_Blood_Decal_01", Vector(30, 110, 110), 0)
	end,
	-- A gizmo around a pineapple, drag its handles with the mouse when the cursor is free (e.g. with Sandbox's context menu open)
	Gizmo = function(spot)
		local fruit = Keep(StaticMesh(OnPedestal(spot, 1), Rotator(0, 20, 0), "nanos-world::SM_Fruit_Pineapple_01"))
		fruit:SetScale(Vector(2, 2, 2))
		local gizmo = Gizmo()
		-- Only shown while the local character is inside a sphere trigger of GIZMO_RANGE around the pedestal, re-centred on the fruit (it may have been dragged) each time it comes back
		local is_active = false
		Keep(gizmo)
		-- The fruit follows the handles: the gizmo sits 50 above its pivot, at scale 1 for the fruit's 2
		gizmo:Subscribe("Transform", function(_, location, rotation, scale)
			if (not fruit:IsValid()) then return end
			fruit:SetLocation(location - Vector(0, 0, 50))
			fruit:SetRotation(rotation)
			fruit:SetScale(scale * 2)
		end)
		-- A WebUI in front (Sandbox's HUD with its context menu open) keeps the clicks from reaching the gizmo itself, so they are handed to it here
		Input.Subscribe("MouseDown", function(key)
			if (key == "LeftMouseButton" and is_active and gizmo:IsValid() and Input.IsMouseEnabled()) then gizmo:PressPointer() end
		end)
		Input.Subscribe("MouseUp", function(key)
			if (key == "LeftMouseButton" and is_active and gizmo:IsValid()) then gizmo:ReleasePointer() end
		end)
		local function IsLocalCharacter(entity)
			local player = Client.GetLocalPlayer()
			return player and player:GetControlledCharacter() == entity
		end
		local area = Keep(Trigger(OnPedestal(spot, 1), Rotator(), Vector(GIZMO_RANGE), TriggerType.Sphere, false, Color.WHITE, { "Character" }))
		area:Subscribe("BeginOverlap", function(_, entity)
			if (is_active or not IsLocalCharacter(entity) or not gizmo:IsValid() or not fruit:IsValid()) then return end
			gizmo:Activate(fruit:GetLocation() + Vector(0, 0, 50), fruit:GetRotation(), Vector(1, 1, 1))
			is_active = true
		end)
		area:Subscribe("EndOverlap", function(_, entity)
			if (not is_active or not IsLocalCharacter(entity) or not gizmo:IsValid()) then return end
			gizmo:Deactivate()
			is_active = false
		end)
		return nil
	end,
	WebUI = function(spot)
		local ui = Keep(WebUI("Playground Screen", "file://ui/screen.html", WidgetVisibility.Hidden, false, false, SCREEN_W * SCREEN_RES, SCREEN_H * SCREEN_RES))
		local plane = ScreenPlane(spot)
		plane:SetMaterialFromWebUI(ui)
		Matte(plane)
		return plane
	end,
	-- A security camera high in the gallery's corner beside the screen (the one away from the door), looking down across the room at its centre, brought
	-- out of the corner along its view so its body clears both walls
	SceneCapture = function(spot)
		local corner = Playground.At(spot, -455, 45, 370)
		local look = (Playground.At(spot, 0, 500, 90) - corner):ToOrientationRotator()
		local at = corner + look:GetForwardVector() * 50
		Keep(StaticMesh(at, look, "nanos-world::SM_Camera", CollisionType.NoCollision))
		local capture = Keep(SceneCapture(at + look:GetForwardVector() * 20, look, SCREEN_W * SCREEN_RES, SCREEN_H * SCREEN_RES, 0.033, 5000, 90))
		local plane = ScreenPlane(spot)
		plane:SetMaterialFromSceneCapture(capture)
		Matte(plane)
		return plane
	end,
	Widget3D = function(spot)
		local text = Keep(Widget(NativeWidget.Text))
		text:CallBlueprintEvent("SetText", "Widget3D\na UMG widget in the world")
		-- Widgets render unlit, so white text glows at night: dark text on the light screen instead
		-- The text's own color is an FSlateColor, which Lua cannot pass; a Border tints its content with a plain linear color
		local widget = Keep(Widget(NativeWidget.Border))
		widget:AddChild(text)
		pcall(function()
			widget:CallBlueprintEvent("SetBrushColor", Color(0, 0, 0, 0))
			widget:CallBlueprintEvent("SetContentColorAndOpacity", Color(0, 0, 0))
		end)
		local widget_3d = widget:SpawnWidget3D(ScreenCenter(spot, 8), Rotator(0, spot.rotation.Yaw + 90, 0), WidgetSpace.World, false,
			Vector2D(SCREEN_W * WIDGET_RES, SCREEN_H * WIDGET_RES))
		widget_3d:SetScale(Vector(1 / WIDGET_RES, 1 / WIDGET_RES, 1 / WIDGET_RES))
		return widget_3d
	end,
}

Package.Subscribe("Load", function()
	for name, spawn in pairs(CLIENT_EXHIBITS) do
		local spot = Playground.Spot("Entities_" .. name)

		if (spot) then
			local ok, entity = pcall(spawn, spot)

			if (not ok) then
				Console.Warn("Playground: client exhibit '%s' failed: %s", name, tostring(entity))
			elseif (entity) then
				Keep(entity)
			end
		end
	end
end)

Package.Subscribe("Unload", function()
	for _, entity in ipairs(spawned) do
		if (entity and entity.IsValid and entity:IsValid()) then
			entity:Destroy()
		end
	end
	spawned = {}
end)

-- The fountain's running water (its particle comes from the server, Server/Zones/Hub.lua): full volume within 1.5 m, silent past 9 m
local FOUNTAIN_VOLUME = 0.2
local fountain_sound = nil

Package.Subscribe("Load", function()
	local spot = Playground.Spot("Hub_FountainWater")
	if (spot) then
		fountain_sound = Sound(spot.location, "nanos-world::A_Waterfall", false, false, SoundType.SFX, FOUNTAIN_VOLUME, 1, 150, 900, AttenuationFunction.NaturalSound, false, SoundLoopMode.Forever)
	end
end)

Package.Subscribe("Unload", function()
	if (fountain_sound and fountain_sound:IsValid()) then fountain_sound:Destroy() end
end)

-- Fireworks from the lookout tower (Server/Zones/Physics.lua): a trail and launch whistle following each shell, then its burst in random colors
Events.SubscribeRemote("Playground:FireworkLaunch", function(shell)
	if (not shell or not shell:IsValid()) then return end
	local trail = Particle(Vector(), Rotator(), "ts-fireworks::PS_TS_FireworksShell", false, true)
	trail:AttachTo(shell, AttachmentRule.SnapToTarget, "", 1)
	local sound = Sound(Vector(), "ts-fireworks::A_Firework_Launch_Cue", false, true, SoundType.SFX, 1, 1.5, 400, 100000)
	sound:AttachTo(shell)
end)

Events.SubscribeRemote("Playground:FireworkBurst", function(location, asset)
	Sound(location, "ts-fireworks::A_Firework_Explosion_Fizz_Cue", false, true, SoundType.SFX, 3, 1, 400, 100000)
	local burst = Particle(location, Rotator(0, math.random(0, 359), 0), asset, true, true)
	burst:SetParameterColor("BlastColor", Color.RandomPalette())
	burst:SetParameterColor("SparkleColor", Color.RandomPalette())
	burst:SetParameterColor("BurstColor", Color.RandomPalette())
	burst:SetParameterFloat("BurstMulti", math.random(50, 300) / 100)
	burst:SetParameterFloat("SparkleMulti", math.random(50, 300) / 100)
end)

-- Lift music: plays on the lookout tower's cage while it rides (Server/Zones/Physics.lua), fading out as it arrives
local LIFT_MUSIC = "nanos-world::A_LocalForecast"
local LIFT_MUSIC_VOLUME = 0.3
local LIFT_MUSIC_FADE = 1.5
-- Heard from inside the cage and just around it: full volume within the inner radius, gone at the falloff distance
local LIFT_MUSIC_INNER, LIFT_MUSIC_FALLOFF = 120, 700

Events.SubscribeRemote("Playground:LiftMusic", function(cage, travel)
	if (not cage or not cage:IsValid()) then return end
	local music = Sound(cage:GetLocation(), LIFT_MUSIC, false, false, SoundType.Music, LIFT_MUSIC_VOLUME, 1, LIFT_MUSIC_INNER, LIFT_MUSIC_FALLOFF)
	music:AttachTo(cage, AttachmentRule.SnapToTarget, "", 0)
	Timer.SetTimeout(function()
		if (music:IsValid()) then music:FadeOut(LIFT_MUSIC_FADE, 0, true) end
	end, math.max(0, travel - LIFT_MUSIC_FADE) * 1000)
end)

-- One-shot sounds the server asks for (Playground.PlaySound)
Events.SubscribeRemote("Playground:Sound", function(location, asset, falloff, volume)
	Sound(location, asset, false, true, SoundType.SFX, volume or 1, 1, 200, falloff or 2500)
end)
