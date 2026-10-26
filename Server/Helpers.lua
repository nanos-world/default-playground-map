-- Helpers the zones share to spawn their entities: props, fixed scenery, weapons on tables, buttons, texts and sounds

-- A weapon table's length along its local X (entities.py and range.py "table")
local WEAPON_TABLE_LENGTH = 210

-- The "+1" a hit pops up
local SCORE_COLOR = Color(1, 0.8, 0.1)

-- A refillable physics Prop of asset; options (all optional): reach, scale (Vector), grab_mode, collision (CollisionType, Normal by default), tint, gravity (false holds it in the air), unbreakable (Sandbox does not break it), one_way (vehicles push it without feeling it)
function Playground.PropSlot(location, rotation, asset, options)
	options = options or {}

	return Playground.Slot(function()
		local prop = Prop(location, rotation, asset, options.collision or CollisionType.Normal, true, options.grab_mode or GrabMode.Enabled)

		if (options.scale) then prop:SetScale(options.scale) end
		if (options.tint) then prop:SetMaterialColorParameter("Tint", options.tint) end
		if (options.gravity == false) then prop:SetGravityEnabled(false) end
		if (options.unbreakable) then prop:SetValue("Unbreakable", true) end
		if (options.one_way) then prop:SetOneWayInteraction(true) end

		return prop
	end, options.reach)
end

-- Fixed scenery the package needs (anchors, doors, hooks, weights), never respawned: a StaticMesh of asset, scaled and tinted when given
function Playground.Fixed(location, rotation, asset, scale, tint)
	local mesh = Playground.Track(StaticMesh(location, rotation, asset))

	if (scale) then mesh:SetScale(scale) end
	if (tint) then mesh:SetMaterialColorParameter("Tint", tint) end

	return mesh
end

-- Where to put a gun lying on its side (shape: a LYING_SHAPES key, ToolGun's when unknown) so the middle of its mesh rests gap above surface, turned by rotation (a 90 roll lays it down)
function Playground.LyingOnSide(shape, surface, rotation, gap)
	local s = LYING_SHAPES[shape] or LYING_SHAPES.ToolGun

	return surface + Vector(0, 0, s.half + (gap or 0)) - rotation:RotateVector(s.centre), rotation
end

-- Where to spawn a melee (shape: a LYING_MELEES key) lying on its side, centred on center (a point on a surface), handle towards yaw + 90 and blade towards yaw - 90: like the guns on a table of that yaw, grip to the visitor at its front (local +Y)
function Playground.LyingMelee(shape, center, yaw)
	local s = LYING_MELEES[shape] or { center = 0, x = 0, lift = 4 }

	-- A -90 roll lays the mesh's Z along -Y (the back) and its Y up
	local rotation = Rotator(0, yaw, -90)

	return center - rotation:RotateVector(Vector(s.x, 0, s.center)) + Vector(0, 0, s.lift), rotation
end

-- default-weapons' weapons by name side by side along a table spot (its local X), lying on their side, grips towards the visitor at the front (local +Y) and muzzles to the back; melees the same way round, centred on the table (their pivot is the handle's end)
function Playground.WeaponsOnTable(spot, names, reach, is_melee)
	if (not NanosWorldWeapons) then return end

	local step = WEAPON_TABLE_LENGTH / #names

	for i, name in ipairs(names) do
		local class = NanosWorldWeapons[name]

		if (class) then
			local along = (i - (#names + 1) / 2) * step
			local location = Playground.At(spot, along, 15, spot.top + 6)
			local rotation = Rotator(0, spot.rotation.Yaw - 90, 90)

			if (is_melee) then
				location, rotation = Playground.LyingMelee(name, Playground.At(spot, along, 0, spot.top), spot.rotation.Yaw)
			end

			Playground.Slot(function() return class(location, rotation) end, reach)
		end
	end
end

-- A "+1" (or text) that rises from location and fades, for a shot that hit something on the range or a goal; it destroys itself
function Playground.ScorePop(location, text)
	local pop = TextRender(location, Rotator(), text or "+1", 50, SCORE_COLOR, TextRenderRenderingType.UnlitCameraAligned)
	pop:TranslateTo(location + Vector(0, 0, 80), 0.9)
	pop:SetLifeSpan(1)
end

-- Text on the front of a Board spot, x across it (the visitor's left is -x) and z up it in the panel's own cm; for scores and clocks that change while playing, so spawned here and kept in sync for everybody
function Playground.BoardText(spot, x, z, text, size, color)
	local s = spot.scale
	local location = Playground.At(spot, x * s.X, BOARD_FACE * s.Y + 1, z * s.Z)

	return Playground.Track(TextRender(location, Rotator(0, Playground.FrontYaw(spot), 0), text, size * s.Z, Playground.TextColor(color), TextRenderRenderingType.Unlit))
end

-- A one-shot sound for everyone near it (Sound only exists on clients), heard up to falloff cm away (2500 when nil), at volume (1 when nil)
function Playground.PlaySound(location, asset, falloff, volume)
	Events.BroadcastRemote("Playground:Sound", Reliability.Unreliable, location, asset, falloff, volume)
end

-- A Sandbox LogicButton at location (its base's pivot) and rotation, held still; only with Sandbox, callers skip whatever needs a button without it
-- options (all optional): kind ("PushButton", "Lever", "Switch", nil for Classic), switchable (false: on_activate on every press), is_on (starts activated), scale, cooldown (ms before it takes another press)
-- A switchable one calls on_activate and on_deactivate in turns; both get the pressing player and character (nil when a wire or the code pressed it)
function Playground.Button(location, rotation, label_on, label_off, on_activate, on_deactivate, options)
	options = options or {}

	local button = Playground.Track(LogicButton(location, rotation, "", "", nil, options.switchable ~= false, options.kind))
	button:SetGravityEnabled(false)
	button:SetMassOverride(100000)
	button:SetPhysicsDamping(1000, 1000)
	button:SetActivateLabel(nil, label_on)
	button:SetDeactivateLabel(nil, label_off)

	if (options.scale and options.scale ~= 1) then button:SetScale(Vector(options.scale, options.scale, options.scale)) end
	if (options.cooldown) then button.cooldown = options.cooldown end

	-- Instance overrides: the base still runs (colors, cooldown, linked entities), then the toy reacts
	button.Activate = function(self, ...)
		LogicButton.Activate(self, ...)
		if (on_activate) then on_activate(...) end
	end

	button.Deactivate = function(self, ...)
		LogicButton.Deactivate(self, ...)
		if (on_deactivate) then on_deactivate(...) end
	end

	if (options.is_on) then button:Activate() end

	return button
end

-- A push button on top of a pedestal spot, facing the spot's yaw, that calls on_press on every press
function Playground.PushButton(spot, label, on_press, cooldown)
	return Playground.Button(Playground.Top(spot, 0), Rotator(0, spot.rotation.Yaw, 0), label, label, on_press, nil, { kind = "PushButton", switchable = false, cooldown = cooldown })
end
