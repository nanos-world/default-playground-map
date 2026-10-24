-- Shooting range: weapons on the armory tables, the targets of the short and long ranges and their shooting game, grenades, exploding barrels and construction props with things to shoot on them (every hit scores a +1) at the explosives pit

-- The targets of the short and long ranges (range.py "Range_<Range>_Lane<i>_R<row>_C<column>" spots, the same targets in every lane): Sandbox Target's stand and plate (SM_PG_TargetBase, SM_PG_<Style>_Plate) held still
-- The plate is hinged HINGE_Z over the stand's pivot and swings about its local X: flat away from the shooters when down, upright when up
-- Outside a game one target of each column of a lane stands, at random; a shot one falls and RANGE_IDLE_RISE ms later one of its column stands up again
local HINGE_Z = 5

-- The shooting game: the range's button (range.py "Range_<Range>_Start") starts a round after a short countdown, in which targets pop up and go down again by themselves, and every lane scores the targets it knocks down while they are up
-- Every lane gets as many targets up at the same time, each lane its own at random; as the round goes on more come up at once and they stay up and pause for less
-- The board beside the range (range.py "Range_<Range>_Board") shows the time left, each lane's score and the winner: in the panel's cm, the title, the clock line and one row per lane (label and score)
local BOARD_TITLE_Z, BOARD_CLOCK_Z, BOARD_ROW_Z, BOARD_ROW_STEP = 320, 265, 205, 50
local BOARD_LABEL_X, BOARD_SCORE_X = -70, 110
local BOARD_INK = Color(0, 0, 0)

-- A shootable or a piece of one, its pivot lifted off the construction prop it stands on
local SHOOTABLE_LIFT = 2

-- A thing to shoot on a "Range_Shoot_*" marker: it breaks into its own pieces with a +1 when hit, whether Sandbox knows the mesh or not, and a new pick comes back a while after it is gone (shot, or removed some other way)
local function SpawnShootable(spot)
	local item = RANGE_SHOOTABLES[math.random(#RANGE_SHOOTABLES)]
	local prop = Playground.Track(Prop(spot.location + Vector(0, 0, SHOOTABLE_LIFT), Rotator(0, math.random(0, 359), 0), item.asset, CollisionType.Normal, true, GrabMode.Enabled))
	prop:SetValue("Unbreakable", true)

	prop:Subscribe("TakeDamage", function(self)
		if (self.broken) then return false end
		self.broken = true

		local location, yaw = self:GetLocation(), self:GetRotation().Yaw
		local turn = Rotator(0, yaw, 0)

		Playground.ScorePop(location + Vector(0, 0, 30))

		-- Gone before its pieces spawn where it stood
		self:Destroy()

		for _, piece in ipairs(item.pieces) do
			local part = Prop(location + turn:RotateVector(piece.offset), Rotator(piece.rotation.Pitch, yaw + piece.rotation.Yaw, piece.rotation.Roll), piece.asset, CollisionType.Normal, true, GrabMode.Enabled)
			part:SetLifeSpan(RANGE_PIECE_LIFESPAN)
		end

		return false
	end)

	prop:Subscribe("Destroy", function()
		Timer.SetTimeout(function()
			if (Playground.spawned) then SpawnShootable(spot) end
		end, RANGE_SHOOTABLE_RESPAWN)
	end)

	return prop
end

-- An explosive on a barrel spot: Sandbox blows it up (the drums at once, the tanks after leaking and burning a few seconds); a while after it is gone, a new one stands in its place
local function SpawnBarrel(spot, index)
	local barrel = Playground.Track(Prop(spot.location + Vector(0, 0, 5), Rotator(0, index * 37, 0), RANGE_BARREL_ASSETS[(index - 1) % #RANGE_BARREL_ASSETS + 1], CollisionType.Normal, true, GrabMode.Enabled))

	barrel:Subscribe("Destroy", function()
		Timer.SetTimeout(function()
			if (Playground.spawned) then SpawnBarrel(spot, index) end
		end, RANGE_BARREL_RESPAWN)
	end)
end

-- Steps a plate through frames one after the other, then calls done; a new animation cancels the one running
local function Animate(target, frames, done, index)
	index = index or 1
	if (index == 1) then target.animation = (target.animation or 0) + 1 end

	local animation = target.animation
	if (not target.plate:IsValid()) then return end

	local frame = frames[index]
	if (not frame) then
		if (done) then done() end
		return
	end

	target.plate:RotateRelativeTo(Rotator(0, 0, frame.roll), frame.time)

	Timer.SetTimeout(function()
		if (target.animation == animation) then Animate(target, frames, done, index + 1) end
	end, math.floor(frame.time * 1000))
end

local function SpawnTarget(spot)
	local target = { up = true }
	local rotation = Rotator(0, spot.rotation.Yaw, 0)

	target.stand = Playground.Track(Prop(spot.location, rotation, "nanos-world::SM_PG_TargetBase", CollisionType.Normal, false, GrabMode.Disabled))
	target.stand:SetImpulseOnDamage(false)

	target.plate = Playground.Track(Prop(spot.location, rotation, "nanos-world::SM_PG_" .. spot.mesh .. "_Plate", CollisionType.Normal, false, GrabMode.Disabled))
	target.plate:SetImpulseOnDamage(false)
	target.plate:AttachTo(target.stand, AttachmentRule.SnapToTarget, "", 0)
	target.plate:SetRelativeLocation(Vector(0, 0, HINGE_Z))

	target.top = spot.location + Vector(0, 0, spot.top)

	return target
end

-- Up, or down without a hit (a game hiding it)
local function SetUp(target, up)
	if (target.up == up) then return end

	target.up = up
	Animate(target, up and RANGE_TARGET_RISE or RANGE_TARGET_DROP)
end

local function KnockDown(target)
	target.up = false
	Animate(target, RANGE_TARGET_FALL)
	Playground.PlaySound(target.top, RANGE_CLANG.asset, RANGE_CLANG.falloff)
	Playground.ScorePop(target.top + Vector(0, 0, 20))
end

-- The board's texts: the title, the clock and each lane's label and score
local function Board(game)
	local spot = game.board
	if (not spot) then return end

	game.texts = {
		clock = Playground.BoardText(spot, 0, BOARD_CLOCK_Z, "READY", 34, BOARD_INK),
		scores = {}
	}

	Playground.BoardText(spot, 0, BOARD_TITLE_Z, game.config.title or game.name, 42, BOARD_INK)

	for i = 1, #game.lanes do
		local z = BOARD_ROW_Z - (i - 1) * BOARD_ROW_STEP
		Playground.BoardText(spot, BOARD_LABEL_X, z, "LANE " .. i, 38, BOARD_INK)
		game.texts.scores[i] = Playground.BoardText(spot, BOARD_SCORE_X, z, "0", 44, BOARD_INK)
	end
end

local function Show(game, clock)
	if (not game.texts) then return end
	if (clock) then game.texts.clock:SetText(clock) end

	for i, lane in ipairs(game.lanes) do
		game.texts.scores[i]:SetText(tostring(lane.score))
	end
end

local function Clock(seconds)
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

local function Winner(game)
	local best, winners = -1, {}

	for i, lane in ipairs(game.lanes) do
		if (lane.score > best) then
			best, winners = lane.score, { i }
		elseif (lane.score == best) then
			winners[#winners + 1] = i
		end
	end

	if (best == 0) then return "NO HITS" end
	if (#winners > 1) then return "DRAW" end

	return "LANE " .. winners[1] .. " WINS!"
end

local function Lerp(range, t)
	return range[1] + (range[2] - range[1]) * t
end

-- count of lane's targets at random, all different
local function Pick(lane, count)
	local pool = {}
	for _, target in pairs(lane.targets) do pool[#pool + 1] = target end

	local picked = {}
	for _ = 1, math.min(count, #pool) do
		picked[#picked + 1] = table.remove(pool, math.random(#pool))
	end

	return picked
end

-- The same number of targets up in every lane (each lane's own, at random) for the range's pace at this point of the round, then down if still up, then the next ones after a pause
local function Pop(game, round)
	if (game.round ~= round or not Playground.spawned) then return end

	local t = math.min(1, math.max(0, (Server.GetTime() - game.started) / (RANGE_GAME.time * 1000)))
	local up_count = RANGE_GAME.up_count
	local count = math.min(up_count[2], math.floor(Lerp({ up_count[1], up_count[2] + 1 }, t)))

	local up = {}
	for _, lane in ipairs(game.lanes) do
		for _, target in ipairs(Pick(lane, count)) do
			SetUp(target, true)
			up[#up + 1] = target
		end
	end

	Timer.SetTimeout(function()
		if (game.round ~= round) then return end

		for _, target in ipairs(up) do SetUp(target, false) end

		Timer.SetTimeout(function() Pop(game, round) end, math.floor(Lerp(game.config.gap, t) * 1000))
	end, math.floor(Lerp(game.config.up, t) * 1000))
end

local function EachTarget(game, callback)
	for _, lane in ipairs(game.lanes) do
		for _, target in pairs(lane.targets) do callback(target) end
	end
end

-- One target of column up, at random, the others down
local function StandOne(column)
	local chosen = column[math.random(#column)]
	for _, target in ipairs(column) do SetUp(target, target == chosen) end
end

-- Outside a game: one target up in every column of every lane
local function Idle(game)
	for _, lane in ipairs(game.lanes) do
		for _, column in pairs(lane.columns) do StandOne(column) end
	end
end

local function Whistle(game, times)
	if (not game.board) then return end

	local location = Playground.Top(game.board, 0)

	for k = 0, times - 1 do
		Timer.SetTimeout(function() Playground.PlaySound(location, RANGE_WHISTLE.asset, RANGE_WHISTLE.falloff, RANGE_WHISTLE.volume) end, k * RANGE_WHISTLE.gap + 1)
	end
end

local function Finish(game, round)
	if (game.round ~= round) then return end

	game.round = round + 1
	game.running = false

	Show(game, Winner(game))
	Whistle(game, 2)
	Idle(game)
end

local function Start(game)
	if (game.running) then return end

	game.running = true
	game.round = (game.round or 0) + 1

	local round = game.round
	for _, lane in ipairs(game.lanes) do lane.score = 0 end
	EachTarget(game, function(target) SetUp(target, false) end)

	-- Countdown, then the clock ticking down every second while the targets pop
	local left = RANGE_GAME.countdown
	local ticker

	ticker = Timer.SetInterval(function()
		if (game.round ~= round or not Playground.spawned) then
			Timer.ClearInterval(ticker)
			return
		end

		if (left > 0) then
			Show(game, "GET READY  " .. left)
		elseif (left == 0) then
			Show(game, Clock(RANGE_GAME.time))
			game.started = Server.GetTime()
			Whistle(game, 1)
			Pop(game, round)
		elseif (-left >= RANGE_GAME.time) then
			Timer.ClearInterval(ticker)
			Finish(game, round)
			return
		else
			Show(game, Clock(RANGE_GAME.time + left))
		end

		left = left - 1
	end, 1000)

	Show(game, "GET READY  " .. left)
	left = left - 1
end

-- A shot target falls; in a round its lane scores, outside one a target of its column stands up again a moment later
local function OnTargetHit(game, lane, column, target)
	if (not target.up) then return false end

	KnockDown(target)

	if (game.running) then
		lane.score = lane.score + 1
		Show(game)
	else
		Timer.SetTimeout(function()
			if (game.running or not Playground.spawned) then return end

			for _, other in ipairs(column) do
				if (other.up) then return end
			end

			StandOne(column)
		end, RANGE_IDLE_RISE)
	end

	return false
end

-- A range of the game: its lanes (each its targets, by index, its columns and score), its board texts and the round running on it
local function SpawnGame(name, spots)
	local game = { name = name, config = RANGE_GAMES[name] or RANGE_GAMES.Short, lanes = {}, running = false, board = Playground.Spot("Range_" .. name .. "_Board") }

	for _, entry in ipairs(spots) do
		local lane_index, column_index = entry.name:match("_Lane(%d+)_R%d+_C(%d+)$")

		if (lane_index) then
			lane_index, column_index = tonumber(lane_index) + 1, tonumber(column_index) + 1

			game.lanes[lane_index] = game.lanes[lane_index] or { targets = {}, columns = {}, score = 0 }
			local lane = game.lanes[lane_index]

			lane.columns[column_index] = lane.columns[column_index] or {}
			local column = lane.columns[column_index]

			local target = SpawnTarget(entry.spot)
			lane.targets[#lane.targets + 1] = target
			column[#column + 1] = target

			target.plate:Subscribe("TakeDamage", function() return OnTargetHit(game, lane, column, target) end)
		end
	end

	Idle(game)

	-- The button starts a round, Sandbox's LogicButton (shooting it starts one too)
	local start = Playground.Spot("Range_" .. name .. "_Start")
	if (start and Playground.HasSandbox()) then
		Board(game)
		Playground.PushButton(start, "start", function() Start(game) end)
	end
end

Playground.Setup("Range", function()
	if (not NanosWorldWeapons) then
		Console.Warn("Playground: default-weapons not loaded, the armory stays empty")
	else
		for _, group in ipairs(RANGE_ARMORY) do
			local spot = Playground.Spot(group.table)
			if (spot) then Playground.WeaponsOnTable(spot, group.weapons, RANGE_WEAPON_REACH, group.is_melee) end
		end
	end

	-- Grenades on the throwing wall
	local wall = Playground.Spot("Range_Grenade_Throw")
	if (wall) then
		for i = 1, RANGE_GRENADES do
			local location = Playground.At(wall, 0, (i - (RANGE_GRENADES + 1) / 2) * 60, 120)
			Playground.Slot(function() return Grenade(location, Rotator()) end)
		end
	end

	-- Sandbox is what makes them explode
	if (Playground.HasSandbox()) then
		for index, entry in ipairs(Playground.SpotsWith("Range_Grenade_Barrel")) do
			SpawnBarrel(entry.spot, index)
		end
	end

	for _, name in ipairs({ "Short", "Long" }) do
		SpawnGame(name, Playground.SpotsWith("Range_" .. name .. "_Lane"))
	end

	-- On the construction props across the lanes and in the explosives range (range.py cover())
	for _, entry in ipairs(Playground.SpotsWith("Range_Shoot_")) do
		SpawnShootable(entry.spot)
	end
end)
