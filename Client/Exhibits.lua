-- The native entities museum's exhibits whose classes only exist on the client (Server/Zones/Entities.lua spawns the rest)

local OnPedestal = Playground.Top

-- The screens hang on the gallery walls like paintings (entities.py SCREEN_CANVAS): a 320 x 190 canvas from z 80 to 270, the spot on the wall face, local +Y out of it
local SCREEN_W, SCREEN_H, SCREEN_Z = 320, 190, 175

-- Render targets in the screen's proportions, this many pixels per cm
local SCREEN_RES = 3

-- Widget3D draws this many pixels per cm and is scaled back down, so its text sits small on the canvas
local WIDGET_RES = 2.5

-- How close the local character must be for the gizmo exhibit to show its handles
local GIZMO_RANGE = 1500

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
	local plane = Playground.Keep(StaticMesh(ScreenCenter(spot), Rotator(0, spot.rotation.Yaw, 90), "nanos-world::SM_Plane", CollisionType.NoCollision))
	plane:SetScale(Vector(SCREEN_W / 100, SCREEN_H / 100, 1))

	return plane
end

local function IsLocalCharacter(entity)
	local player = Client.GetLocalPlayer()
	return player and player:GetControlledCharacter() == entity
end

-- Exhibits by spot name ("Entities_<name>"), each spawning what it shows; whatever they spawn is kept with Playground.Keep
local CLIENT_EXHIBITS = {
	Billboard = function(spot)
		Playground.Keep(Billboard(OnPedestal(spot, 50), "nanos-world::M_NanosBillboardError", Vector2D(45, 45), false))
	end,
	-- A blood splat projected straight down onto the pad: a Decal already points down at Rotator() (ADecalActor's root carries a -90 pitch that multiplies with the spawn rotation), so only its yaw is set
	Decal = function(spot)
		Playground.Keep(Decal(Playground.Top(spot, 0), Rotator(0, spot.rotation.Yaw + 180, 0), "nanos-world::MI_Blood_Decal_01", Vector(30, 110, 110), 0))
	end,
	-- A gizmo around a pineapple, drag its handles with the mouse when the cursor is free (e.g. with Sandbox's context menu open)
	Gizmo = function(spot)
		local fruit = Playground.Keep(StaticMesh(OnPedestal(spot, 1), Rotator(0, 20, 0), "nanos-world::SM_Fruit_Pineapple_01"))
		fruit:SetScale(Vector(2, 2, 2))

		local gizmo = Playground.Keep(Gizmo())

		-- Only shown while the local character is inside a sphere trigger of GIZMO_RANGE around the pedestal, re-centred on the fruit (it may have been dragged) each time it comes back
		local is_active = false

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

		local area = Playground.Keep(Trigger(OnPedestal(spot, 1), Rotator(), Vector(GIZMO_RANGE), TriggerType.Sphere, false, Color.WHITE, { "Character" }))

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
	end,
	WebUI = function(spot)
		local ui = Playground.Keep(WebUI("Playground Screen", "file://UI/screen.html", WidgetVisibility.Hidden, false, false, SCREEN_W * SCREEN_RES, SCREEN_H * SCREEN_RES))
		local plane = ScreenPlane(spot)
		plane:SetMaterialFromWebUI(ui)
		Matte(plane)
	end,
	-- A security camera high in the gallery's corner beside the screen (the one away from the door), looking down across the room at its centre, brought out of the corner along its view so its body clears both walls
	SceneCapture = function(spot)
		local corner = Playground.At(spot, -455, 45, 370)
		local look = (Playground.At(spot, 0, 500, 90) - corner):ToOrientationRotator()
		local at = corner + look:GetForwardVector() * 50

		Playground.Keep(StaticMesh(at, look, "nanos-world::SM_Camera", CollisionType.NoCollision))

		local capture = Playground.Keep(SceneCapture(at + look:GetForwardVector() * 20, look, SCREEN_W * SCREEN_RES, SCREEN_H * SCREEN_RES, 0.033, 5000, 90))
		local plane = ScreenPlane(spot)
		plane:SetMaterialFromSceneCapture(capture)
		Matte(plane)
	end,
	Widget3D = function(spot)
		local text = Playground.Keep(Widget(NativeWidget.Text))
		text:CallBlueprintEvent("SetText", "Widget3D\na UMG widget in the world")

		-- Widgets render unlit, so white text glows at night: dark text on the light screen instead
		-- The text's own color is an FSlateColor, which Lua cannot pass; a Border tints its content with a plain linear color
		local widget = Playground.Keep(Widget(NativeWidget.Border))
		widget:AddChild(text)

		pcall(function()
			widget:CallBlueprintEvent("SetBrushColor", Color(0, 0, 0, 0))
			widget:CallBlueprintEvent("SetContentColorAndOpacity", Color(0, 0, 0))
		end)

		local widget_3d = Playground.Keep(widget:SpawnWidget3D(ScreenCenter(spot, 8), Rotator(0, spot.rotation.Yaw + 90, 0), WidgetSpace.World, false, Vector2D(SCREEN_W * WIDGET_RES, SCREEN_H * WIDGET_RES)))
		widget_3d:SetScale(Vector(1 / WIDGET_RES, 1 / WIDGET_RES, 1 / WIDGET_RES))
	end,
}

function Playground.SpawnExhibits()
	for name, spawn in pairs(CLIENT_EXHIBITS) do
		local spot = Playground.Spot("Entities_" .. name)

		if (spot) then
			local ok, err = pcall(spawn, spot)

			if (not ok) then
				Console.Warn("Playground: client exhibit '%s' failed: %s", name, tostring(err))
			end
		end
	end
end
