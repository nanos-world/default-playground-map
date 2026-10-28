-- Museum (museum.py): its pictures and the pieces the generic exhibit spots cannot make (Props.lua spawns the rest)
-- Every picture is a Sandbox PhotoFrame (its picture can be changed in the context menu), only when Sandbox runs; on the wall with gravity off, nobody grabs it

-- Gallery spots stand this far out from the wall (museum.py GALLERY_OUT); a gilded frame's back is its pivot, so it goes back almost all the way to hang flat on the wall
local GILDED_BACK = 11

-- The frame faces its local +Y, as its spot does (PhotoFrame turns what it is given by 90)
local function HangPicture(spot, image, style, scale)
	local frame = PhotoFrame(spot.location, Rotator(0, spot.rotation.Yaw - 90, 0), nil, nil, nil, style)
	frame:SetGravityEnabled(false)
	frame:SetGrabMode(GrabMode.Disabled)
	frame:SetScale(Vector(scale, scale, scale))
	frame:SetPhoto(image)

	return frame
end

-- Same heap every time: a small deterministic random generator, so the global one is left alone
local function Random(seed)
	local state = seed

	return function(a, b)
		state = (state * 1103515245 + 12345) % 2147483648
		return a + (b - a) * state / 2147483648
	end
end

-- Lays the bouncy balls of MUSEUM_BALL_HEAP: each { x, y, z, r } in the cabinet's axes
local function HeapBalls()
	local heap = MUSEUM_BALL_HEAP
	local random = Random(heap.seed)
	local balls = {}

	for _ = 1, heap.drops do
		local r = random(heap.radius[1], heap.radius[2])
		local best = nil

		for _ = 1, heap.tries do
			local x, y, z = random(-heap.room.x + r, heap.room.x - r), random(-heap.room.y + r, heap.room.y - r), r

			-- Resting height over each ball it would fall onto: where the two just touch
			for _, b in ipairs(balls) do
				local reach = r + b.r
				local d2 = (x - b.x) ^ 2 + (y - b.y) ^ 2
				if (d2 < reach * reach) then z = math.max(z, b.z + math.sqrt(reach * reach - d2)) end
			end

			if (not best or z < best.z) then best = { x = x, y = y, z = z } end
		end

		if (best.z + r <= heap.room.z) then
			balls[#balls + 1] = { x = best.x, y = best.y, z = best.z, r = r }
		end
	end

	return balls
end

-- A glossy sphere of the bouncy ball material on display, a StaticMesh: it never moves
local function SpawnBouncyBall(location, radius, color)
	local ball = Playground.Track(StaticMesh(location, Rotator(), "nanos-world::SM_Sphere"))
	ball:SetScale(Vector(radius / 50, radius / 50, radius / 50))
	ball:SetMaterial("nanos-world::MI_PG_BouncyBall")
	ball:SetMaterialColorParameter("Tint", color)
end

local function SpawnPictures()
	for k, painting in ipairs(MUSEUM_GALLERY) do
		local spot = Playground.Spot("Museum_Gallery" .. k)

		if (spot) then
			local lift = MUSEUM_GALLERY_MIDDLE - MUSEUM_FRAME_HEIGHTS[painting.style] * MUSEUM_GALLERY_SCALE / 2
			local lifted = { location = spot.location + Vector(0, 0, lift) - spot.rotation:RotateVector(Vector(0, GILDED_BACK, 0)), rotation = spot.rotation }

			Playground.Slot(function() return HangPicture(lifted, MUSEUM_IMAGE_DIR .. painting.image, painting.style, MUSEUM_GALLERY_SCALE) end)
		end
	end

	for name, painting in pairs(MUSEUM_PAINTINGS) do
		local spot = Playground.Spot("Museum_Painting_" .. name)

		if (spot) then
			Playground.Slot(function() return HangPicture(spot, MUSEUM_IMAGE_DIR .. painting.image, painting.style, spot.scale.X) end)
		end
	end
end

Playground.Setup("Museum", function()
	if (Playground.HasSandbox()) then SpawnPictures() end

	local cabinet = Playground.Spot("Museum_BouncyBalls")
	if (cabinet) then
		for k, ball in ipairs(HeapBalls()) do
			local location = Playground.At(cabinet, ball.x, ball.y, ball.z + 1)
			local color = MUSEUM_BALL_COLORS[(k - 1) % #MUSEUM_BALL_COLORS + 1]

			SpawnBouncyBall(location, ball.r, color)
		end
	end

	-- Mingebag Hall of Shame: a heap of junk that never moves
	local shame = Playground.Spot("Museum_Shame")
	if (shame) then
		for _, piece in ipairs(MUSEUM_SHAME_PILE) do
			Playground.Fixed(shame.location + shame.rotation:RotateVector(piece.offset), shame.rotation + piece.rotation, piece.mesh)
		end
	end

	local barrel = Playground.Spot("Museum_Missing")
	if (barrel) then
		Playground.Slot(function()
			local prop = Prop(barrel.location + Vector(0, 0, 5), Rotator(0, 20, 0), "nanos-world::SM_PlasticBarrel_01", CollisionType.Normal, true, GrabMode.Disabled)
			prop:SetMaterial("nanos-world::MI_PG_MissingProp")
			return prop
		end, MUSEUM_MISSING_REACH)
	end
end)
