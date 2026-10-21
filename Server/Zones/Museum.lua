-- Museum (museum.py): its pictures and the pieces the generic exhibit spots cannot make (Props.lua spawns the rest)

-- Every picture is a Sandbox PhotoFrame (its picture can be changed in the context menu), only when Sandbox runs; on the wall with gravity off, nobody
-- grabs it. The frame faces its local +Y, as its spot does (PhotoFrame turns what it is given by 90); styles are PhotoFrame.styles
-- The gallery's pictures (Client/images/museum) in gilded frames on its "Museum_Gallery<n>" spots, in museum.py GALLERY's order (picture n matches
-- plaque n), all at GALLERY_SCALE with their middles GALLERY_MIDDLE above the spot (playground_props.py: PaintingTall 202, PaintingWide 180 tall)
local GALLERY_SCALE = 0.75
local GALLERY_MIDDLE = 77
local GALLERY_PAINTINGS = {
	{ image = "mona_lisa.jpg", style = "gold_tall" },
	{ image = "scream.jpg", style = "gold_tall" },
	{ image = "starry.jpg", style = "gold_wide" },
	{ image = "pearl.jpg", style = "gold_tall" },
	{ image = "napoleon.jpg", style = "gold_wide" },
	{ image = "persistence.jpg", style = "gold_wide" },
}
local FRAME_HEIGHTS = { gold_square = 202, gold_wide = 180, gold_tall = 202 }
-- Gallery spots stand this far out from the wall (museum.py GALLERY_OUT); a gilded frame's back is its pivot, so it goes back almost all the way to
-- hang flat on the wall
local GILDED_BACK = 11
-- The gilded paintings on "Museum_Painting_<name>" spots (scaled by the spot): their frame and picture (Client/images/museum)
local PAINTINGS = {
	Creator = { style = "gold_square", image = "creator.jpg" },
}
-- The Hall of Shame's heap, laid out by hand as static meshes (no physics: a dropped heap kept blowing itself across the hall): mesh, offset from the
-- spot (x into the hall, y across it, z up), rotation
local SHAME_PILE = {
	{ "nanos-world::SM_Tire_01", Vector(-40, 30, 31), Rotator(90, 0, 0) },
	{ "nanos-world::SM_MicrowaveOven", Vector(-40, 30, 62), Rotator(0, 30, 0) },
	{ "nanos-world::SM_Bucket5Gallon", Vector(-35, 25, 151), Rotator(0, 10, 180) },
	{ "nanos-world::SM_CartonBox_01", Vector(45, -40, 0), Rotator(0, 20, 0) },
	{ "nanos-world::SM_Crate_01", Vector(40, -35, 65), Rotator(0, -15, 0) },
	{ "nanos-world::SM_Fruit_Watermelon_01", Vector(100, -15, 14), Rotator(0, 40, 0) },
	{ "nanos-world::SM_TV", Vector(30, 60, 0), Rotator(0, 60, -12) },
	{ "nanos-world::SM_TrashCan_01", Vector(-20, -75, 33), Rotator(90, 0, 0) },
	{ "nanos-world::SM_WoodenChair", Vector(-80, -10, 30), Rotator(0, 120, 90) },
	{ "nanos-world::SM_RockingChair", Vector(90, 40, 0), Rotator(0, -140, 0) },
}
local IMAGE_DIR = "package://" .. Package.GetName() .. "/Client/images/museum/"

local function HangPicture(class, spot, image, style, scale)
	local frame = class(spot.location, Rotator(0, spot.rotation.Yaw - 90, 0), nil, nil, nil, style)
	frame:SetGravityEnabled(false)
	frame:SetGrabMode(GrabMode.Disabled)
	frame:SetScale(Vector(scale, scale, scale))
	frame:SetMaterialTextureParameter("Texture", image, 1)
	return frame
end

-- Garry's Mod bouncy balls filling their glass cabinet: glossy spheres in the classic four colors on the bouncy rubber, heaped up to near its top and held
-- there (no gravity, nobody grabs them: they are on display)
local BALL_COLORS = { Color(0.8, 0.02, 0.02), Color(0.02, 0.05, 0.8), Color(0.85, 0.7, 0.02), Color(0.03, 0.75, 0.05) }
local BALL_REACH = 600
-- The heap: their radius range and the room inside the glass from the spot (playground_props.py VitrineCabinet: 98 x 62 inside, 150 tall, the spot's X
-- across its depth and Y along its width)
local BALL_RADIUS = { 16, 21 }
local BALL_ROOM = { x = 30, y = 48, z = 148 }
-- The heap is built once, ball by ball: each one dropped at the lowest of BALL_TRIES random spots, where it rests on the floor or the balls under it,
-- until BALL_DROPS have been tried (the ones that would stick out of the top are left out)
local BALL_TRIES = 300
local BALL_DROPS = 80
local BALL_SEED = 99

-- Same heap every time: a small deterministic random generator, so the global one is left alone
local function Random(seed)
	local state = seed
	return function(a, b)
		state = (state * 1103515245 + 12345) % 2147483648
		return a + (b - a) * state / 2147483648
	end
end

local function HeapBalls()
	local random = Random(BALL_SEED)
	local balls = {}
	for _ = 1, BALL_DROPS do
		local r = random(BALL_RADIUS[1], BALL_RADIUS[2])
		local best = nil
		for _ = 1, BALL_TRIES do
			local x, y, z = random(-BALL_ROOM.x + r, BALL_ROOM.x - r), random(-BALL_ROOM.y + r, BALL_ROOM.y - r), r
			-- Resting height over each ball it would fall onto: where the two just touch
			for _, b in ipairs(balls) do
				local reach = r + b.r
				local d2 = (x - b.x) ^ 2 + (y - b.y) ^ 2
				if (d2 < reach * reach) then z = math.max(z, b.z + math.sqrt(reach * reach - d2)) end
			end
			if (not best or z < best.z) then best = { x = x, y = y, z = z } end
		end
		if (best.z + r <= BALL_ROOM.z) then
			balls[#balls + 1] = { x = best.x, y = best.y, z = best.z, r = r }
		end
	end
	return balls
end

-- The plastic barrel on the missing texture stand, painted with it too
local MISSING_REACH = 1500

local function BouncyBall(location, radius, color)
	local ball = Prop(location, Rotator(), "nanos-world::SM_Sphere", CollisionType.Normal, false, GrabMode.Disabled)
	ball:SetScale(Vector(radius / 50, radius / 50, radius / 50))
	ball:SetMaterial("nanos-world::MI_PG_BouncyBall")
	ball:SetMaterialColorParameter("Tint", color)
	ball:SetPhysicalMaterial("nanos-world::PM_RubberBouncy")
	return ball
end

Playground.Setup("Museum", function()
	local frame_class = Playground.FindClass("PhotoFrame", { Prop })

	for k, painting in ipairs(GALLERY_PAINTINGS) do
		local spot = frame_class and Playground.Spot("Museum_Gallery" .. k)
		if (spot) then
			local lift = GALLERY_MIDDLE - FRAME_HEIGHTS[painting.style] * GALLERY_SCALE / 2
			local lifted = { location = spot.location + Vector(0, 0, lift) - spot.rotation:RotateVector(Vector(0, GILDED_BACK, 0)), rotation = spot.rotation }
			Playground.Slot(function() return HangPicture(frame_class, lifted, IMAGE_DIR .. painting.image, painting.style, GALLERY_SCALE) end)
		end
	end

	for name, painting in pairs(PAINTINGS) do
		local spot = frame_class and Playground.Spot("Museum_Painting_" .. name)
		if (spot) then
			Playground.Slot(function() return HangPicture(frame_class, spot, IMAGE_DIR .. painting.image, painting.style, spot.scale.X) end)
		end
	end

	local balls = Playground.Spot("Museum_BouncyBalls")
	if (balls) then
		for k, ball in ipairs(HeapBalls()) do
			local location = Playground.At(balls, ball.x, ball.y, ball.z + 1)
			local color = BALL_COLORS[(k - 1) % #BALL_COLORS + 1]
			Playground.Slot(function() return BouncyBall(location, ball.r, color) end, BALL_REACH)
		end
	end

	-- Mingebag Hall of Shame: a heap of junk that never moves
	local shame = Playground.Spot("Museum_Shame")
	if (shame) then
		for _, piece in ipairs(SHAME_PILE) do
			local mesh, offset, rotation = piece[1], piece[2], piece[3]
			StaticMesh(shame.location + shame.rotation:RotateVector(offset), shame.rotation + rotation, mesh, CollisionType.Normal)
		end
	end

	local barrel = Playground.Spot("Museum_Missing")
	if (barrel) then
		Playground.Slot(function()
			local prop = Prop(barrel.location + Vector(0, 0, 5), Rotator(0, 20, 0), "nanos-world::SM_PlasticBarrel_01", CollisionType.Normal, true, GrabMode.Disabled)
			prop:SetMaterial("nanos-world::MI_PG_MissingProp")
			return prop
		end, MISSING_REACH)
	end
end)
