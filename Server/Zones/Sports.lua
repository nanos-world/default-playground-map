-- Sports corner (sports.py): a football on the pitch whose goals score on a scoreboard, a basketball on the court whose hoop scores, and the bell frame whose bells ring a note each when they are shot or pressed (E)
-- The balls are Sandbox's Ball (kicked by running into them), so the balls, the goals and the scoreboard only come with Sandbox

local BALL_MESH = "nanos-world::SM_PG_Ball"

-- Box Trigger inside a goal's net, from its spot: playground_props.py SoccerGoal has its mouth (300 x 200) on the spot facing local +Y and its net behind (local -Y), 120 deep on the ground and 60 under the crossbar
-- A Trigger only tests the ball's centre, so the box stays a ball's radius (11) inside the net all round: a ball is in once it is wholly over the line, and one touching the net from behind or above never reaches it
local GOAL_CENTRE, GOAL_EXTENT = Vector(0, -31, 88), Vector(135, 19, 88)

-- A ball that scored cannot score again until its centre has left this box around the goal (the net and 2.4 m of pitch in front of it), so one lying at the back of the net, or rolling about in it, counts once
local GOAL_AREA_CENTRE, GOAL_AREA_EXTENT = Vector(0, 40, 120), Vector(260, 200, 150)

-- Out of bounds: a ball going further than OUT_MARGIN past the lines of the pitch or the court is out, the whistle blows and OUT_DELAY ms later it is put back at rest (kicks and grabs disabled for SETTLE_TIME s)
-- On the pitch it goes on the nearest point of the side line, or in the nearest corner when it went over a goal line; on the court on the basketball's spot
local OUT_MARGIN = 40
local OUT_HEIGHT = 600
local OUT_DELAY = 1000
local SETTLE_TIME = 0.3

-- The pitch's playing area (sports.py PITCH: 2400 along between the goal lines, 1300 across), and the height of a ball's centre resting on it
local PITCH_HALF_ALONG, PITCH_HALF_ACROSS = 1200, 650
local PITCH_LIFT = 12

-- The court (sports.py COURT, 1100 x 900) from the hoop's pole (HOOP_IN from its far edge, looking along its local +Y into the court): its middle and half size
local COURT_FROM_HOOP, COURT_HALF_ACROSS, COURT_HALF_ALONG = 400, 550, 450

-- playground_props.py BasketHoop, from the pole along local +Y: the backboard's face 123 in front (180 wide, 257 to 362 up), the rim (r 30) centred 165 in front, 270 up, and its net hanging 42 below it
-- A basket is a thrown ball hitting the red square on the board (59 x 47, its middle 36 over the rim): it scores and is carried over the rim (OVER_RIM, in BANK_TIME seconds), dropping in from there
local SQUARE_CENTRE, SQUARE_EXTENT = Vector(0, 133, 306), Vector(30, 10, 24)
local OVER_RIM = Vector(0, 165, 292)
local BANK_TIME = 0.2

-- A ball scoring loses this part of its speed, so it stays in the net or drops through the hoop instead of bouncing out
local GOAL_DAMP = 0.8

-- The scoreboard (sports.py SCOREBOARD, a Board): the title and the two scores on it, in the panel's cm
local SCORE_TITLE_Z, SCORE_Z = 300, 165
local SCORE_X = 120
local SCORE_INK = Color(0, 0, 0)

-- The bells (playground_props.py BellFrame): one every BELL_STEP along its local X, hanging from BELL_Z
local BELL_STEP, BELL_Z = 50, 200

local function IsBall(entity)
	return entity and entity:IsValid() and entity:IsA(Prop) and entity:GetMesh() == BALL_MESH
end

-- Takes part of ball's speed away (only sideways when flat, so a falling ball keeps falling through the hoop)
local function Slow(ball, part, flat)
	local velocity = ball:GetVelocity()
	if (flat) then velocity = Vector(velocity.X, velocity.Y, math.max(velocity.Z, 0)) end

	ball:AddImpulse(velocity * -part, true)
end

local function Cheer(location, text)
	Playground.ScorePop(location, text)
	Playground.PlaySound(location, SPORTS_CHEER.asset, SPORTS_CHEER.falloff, SPORTS_CHEER.volume)
end

-- The pitch's scoreboard: the goals of each side and the texts showing them
local Score = { goals = { 0, 0 }, texts = {} }

function Score.Show()
	for side, text in pairs(Score.texts) do
		if (text:IsValid()) then text:SetText(tostring(Score.goals[side])) end
	end
end

-- The side (1 on the visitor's left as they read the board, 2 on the right) a goal into goal_spot counts for: the one playing towards it from the other end
function Score.SideFor(board, goal_spot)
	return board.rotation:UnrotateVector(goal_spot.location - board.location).X < 0 and 2 or 1
end

-- Freezes a ball (Sandbox's Ball: no kick, no grab) or lets it go again
local function Freeze(ball, frozen)
	if (ball.SetKickEnabled) then ball:SetKickEnabled(not frozen) end
	ball:SetGrabMode(frozen and GrabMode.Disabled or GrabMode.Auto)
end

-- Puts a ball back at rest with TranslateTo, blocking kicks and grabs briefly so they cannot cancel the reset
local function Settle(ball, location)
	Freeze(ball, true)
	ball:SetLocation(location)
	ball:TranslateTo(location, SETTLE_TIME, 0)

	local timer = Timer.SetTimeout(function()
		if (ball:IsValid()) then Freeze(ball, false) end
	end, math.floor(SETTLE_TIME * 1000))
	Timer.Bind(timer, ball)
end

-- A goal by any ball: GOAL! and a point on the board, the ball frozen in the net and back on the centre spot (kick_off, its centre's height) a moment later
local function Goal(spot, ball, kick_off, side)
	Cheer(Playground.At(spot, 0, 0, 230), "GOAL!")

	if (side) then
		Score.goals[side] = Score.goals[side] + 1
		Score.Show()
	end

	Freeze(ball, true)

	Timer.SetTimeout(function()
		if (not Playground.spawned or not ball:IsValid() or ball:GetHandler()) then return end

		if (kick_off) then
			Settle(ball, kick_off)
		else
			Freeze(ball, false)
		end
	end, SPORTS_GOAL_RESET)
end

-- Where a ball out of the pitch (pitch is { centre, rotation, lift }) goes back: on the side line where it crossed, or in the corner nearest to it when it went over a goal line
local function ThrowIn(pitch, ball)
	local local_location = pitch.rotation:UnrotateVector(ball:GetLocation() - pitch.centre)
	local along, across = local_location.X, local_location.Y
	local side = across < 0 and -PITCH_HALF_ACROSS or PITCH_HALF_ACROSS

	if (math.abs(along) > PITCH_HALF_ALONG) then
		along = along < 0 and -PITCH_HALF_ALONG or PITCH_HALF_ALONG
	end

	return pitch.centre + pitch.rotation:RotateVector(Vector(along, side, 0)) + Vector(0, 0, pitch.lift)
end

-- A box Trigger over an area (centre, rotation, half extent in the area's frame): any ball leaving it, nobody carrying it and not in a net, is whistled out and put back where back_to(ball) says, if it is still outside a moment later
local function OutOfBounds(centre, rotation, extent, back_to)
	local area = Playground.Track(Trigger(centre, rotation, extent, TriggerType.Box, false, Color.WHITE, { "Prop" }))

	area:Subscribe("EndOverlap", function(_, ball)
		if (not IsBall(ball)) then return end

		Timer.SetTimeout(function()
			if (not ball:IsValid() or ball:GetValue("Playground:Scored") or ball:GetHandler() or ball:GetAttachedTo()) then return end

			local away = rotation:UnrotateVector(ball:GetLocation() - centre)
			if (math.abs(away.X) <= extent.X and math.abs(away.Y) <= extent.Y and math.abs(away.Z) <= extent.Z) then return end

			Playground.PlaySound(ball:GetLocation(), SPORTS_WHISTLE.asset, SPORTS_WHISTLE.falloff, SPORTS_WHISTLE.volume)
			Settle(ball, back_to(ball))
		end, OUT_DELAY)
	end)
end

local function Swing(bell, rest, index)
	index = index or 1

	local frame = SPORTS_BELL_SWING[index]
	if (not frame or not bell:IsValid()) then return end

	bell:RotateTo(Rotator(0, rest.Yaw, frame.roll), frame.time)
	Timer.SetTimeout(function() Swing(bell, rest, index + 1) end, math.floor(frame.time * 1000))
end

local function SpawnBell(spot, index)
	local count = #SPORTS_BELL_NOTES
	local note = SPORTS_BELL_NOTES[index]
	local scale = SPORTS_BELL_SCALE[1] + (SPORTS_BELL_SCALE[2] - SPORTS_BELL_SCALE[1]) * (index - 1) / (count - 1)
	local location = Playground.At(spot, (index - (count + 1) / 2) * BELL_STEP, 0, BELL_Z)
	local rest = Rotator(0, spot.rotation.Yaw, 0)

	local bell = Prop(location, rest, "nanos-world::SM_PG_Bell", CollisionType.Normal, false, GrabMode.Enabled)
	bell:SetScale(Vector(scale))
	bell:SetImpulseOnDamage(false)
	bell:SetPhysicsDamping(1000, 1000)

	local last = 0

	local function Ring()
		local now = Server.GetTime()
		if (now - last < SPORTS_BELL_COOLDOWN) then return end
		last = now

		Playground.PlaySound(bell:GetLocation(), SPORTS_BELL_SOUND.path .. note .. ".ogg", SPORTS_BELL_SOUND.falloff, SPORTS_BELL_SOUND.volume)
		Playground.ScorePop(bell:GetLocation() - Vector(0, 0, 50 * scale), note:sub(1, 1))
		Swing(bell, rest)
	end

	bell:Subscribe("TakeDamage", function()
		Ring()
		return false
	end)

	bell:Subscribe("Interact", function()
		Ring()
		return false
	end)

	return bell
end

-- A ball (Sandbox's, anyone's, or the two of the corner) wholly inside a goal's net scores once, until it has left the goal's area
local function SpawnGoal(spot, board, kick_off)
	local side = board and Score.SideFor(board, spot)

	local trigger = Playground.Track(Trigger(Playground.At(spot, GOAL_CENTRE.X, GOAL_CENTRE.Y, GOAL_CENTRE.Z), spot.rotation, GOAL_EXTENT, TriggerType.Box, false, Color.WHITE, { "Prop" }))
	trigger:Subscribe("BeginOverlap", function(_, ball)
		if (not IsBall(ball) or ball:GetValue("Playground:Scored")) then return end

		ball:SetValue("Playground:Scored", true)
		Slow(ball, GOAL_DAMP)
		Goal(spot, ball, kick_off, side)
	end)

	local area = Playground.Track(Trigger(Playground.At(spot, GOAL_AREA_CENTRE.X, GOAL_AREA_CENTRE.Y, GOAL_AREA_CENTRE.Z), spot.rotation, GOAL_AREA_EXTENT, TriggerType.Box, false, Color.GREEN, { "Prop" }))
	area:Subscribe("EndOverlap", function(_, ball)
		if (IsBall(ball)) then ball:SetValue("Playground:Scored", false) end
	end)
end

-- The red square on the hoop's board: a thrown ball hitting it is stopped (so it falls straight through the rim) and carried over the rim, +2
local function SpawnHoop(hoop)
	local over_rim = Playground.At(hoop, OVER_RIM.X, OVER_RIM.Y, OVER_RIM.Z)
	local square = Playground.At(hoop, SQUARE_CENTRE.X, SQUARE_CENTRE.Y, SQUARE_CENTRE.Z)

	local trigger = Playground.Track(Trigger(square, hoop.rotation, SQUARE_EXTENT, TriggerType.Box, false, Color.YELLOW, { "Prop" }))
	trigger:Subscribe("BeginOverlap", function(_, ball)
		if (not IsBall(ball) or ball:GetHandler() or ball:GetAttachedTo()) then return end

		Slow(ball, 1)
		ball:TranslateTo(over_rim, BANK_TIME, 0)
		Cheer(over_rim + Vector(0, 0, 80), "+2")
	end)
end

Playground.Setup("Sports", function()
	local bells = Playground.Spot("Sports_Bells")
	if (bells) then
		for index = 1, #SPORTS_BELL_NOTES do
			Playground.Slot(function() return SpawnBell(bells, index) end, SPORTS_BELL_REACH)
		end
	end

	if (not Playground.HasSandbox()) then return end

	-- Sandbox's BALL_STYLES ids, each resting on its spot's floor
	local centre = Playground.Spot("Sports_Ball")
	local football = centre and Playground.Slot(function() return Ball(centre.location, Rotator(), nil, nil, nil, "Soccer") end, SPORTS_BALL_REACH)

	local basket = Playground.Spot("Sports_Basketball")
	if (basket) then
		Playground.Slot(function() return Ball(basket.location, Rotator(), nil, nil, nil, "Basketball") end, SPORTS_BALL_REACH)
	end

	-- The scoreboard, and its button putting both sides back to 0 and the football on the centre spot
	local board = Playground.Spot("Sports_Scoreboard")
	if (board) then
		Playground.BoardText(board, 0, SCORE_TITLE_Z, "GOALS", 60, SCORE_INK)
		Playground.BoardText(board, 0, SCORE_Z, "-", 110, SCORE_INK)
		Score.texts[1] = Playground.BoardText(board, -SCORE_X, SCORE_Z, "0", 150, SCORE_INK)
		Score.texts[2] = Playground.BoardText(board, SCORE_X, SCORE_Z, "0", 150, SCORE_INK)
	end

	local reset = Playground.Spot("Sports_ScoreReset")
	if (reset) then
		Playground.PushButton(reset, "reset score", function()
			Score.goals = { 0, 0 }
			Score.Show()
			if (football) then Playground.Respawn(football, true) end
		end)
	end

	local goals = Playground.SpotsWith("Sports_Goal")
	local kick_off = centre and centre.location + Vector(0, 0, PITCH_LIFT)

	for _, entry in ipairs(goals) do
		SpawnGoal(entry.spot, board, kick_off)
	end

	-- Any ball leaving the pitch (not into a net) goes back on its nearest line
	if (centre and #goals == 2) then
		local axis = goals[2].spot.location - goals[1].spot.location
		local pitch = { centre = centre.location, rotation = Rotator(0, math.deg(math.atan(axis.Y, axis.X)), 0), lift = PITCH_LIFT }
		local extent = Vector(PITCH_HALF_ALONG + OUT_MARGIN, PITCH_HALF_ACROSS + OUT_MARGIN, OUT_HEIGHT)

		OutOfBounds(pitch.centre, pitch.rotation, extent, function(ball) return ThrowIn(pitch, ball) end)
	end

	-- Any ball leaving the court goes back on the basketball's spot
	local hoop = Playground.Spot("Sports_Hoop")
	if (hoop and basket) then
		local extent = Vector(COURT_HALF_ACROSS + OUT_MARGIN, COURT_HALF_ALONG + OUT_MARGIN, OUT_HEIGHT)
		local spawn = basket.location + Vector(0, 0, 14)

		OutOfBounds(Playground.At(hoop, 0, COURT_FROM_HOOP, 0), hoop.rotation, extent, function() return spawn end)
	end

	if (hoop) then SpawnHoop(hoop) end
end)
