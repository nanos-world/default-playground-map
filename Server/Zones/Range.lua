-- Shooting range: weapons on the armory tables, the targets of the short and long ranges and their shooting game, grenades, exploding barrels and construction props
-- with things to shoot on them (every hit scores a +1) at the explosives pit

-- Every weapon in default-weapons (grenades are at the explosives range), one table per family laid out from one end to the other
-- The first four tables stand in front of the short range, the rest in front of the long range
local ARMORY = {
	{ table = "Range_Armory_Pistols", weapons = { "Glock", "M1911", "Makarov", "DesertEagle", "ColtPython" } },
	{ table = "Range_Armory_SMGs", weapons = { "AP5", "UMP45", "P90", "SMG11", "Sten" } },
	{ table = "Range_Armory_Shotguns", weapons = { "Moss500", "Rem870", "Ithaca37", "SPAS12" } },
	{ table = "Range_Armory_Melee", weapons = { "Knife", "Crowbar", "BaseballBat" } },
	{ table = "Range_Armory_Assault", weapons = { "AK47", "AR4", "GE36", "AK5C" } },
	{ table = "Range_Armory_Carbines", weapons = { "AK74U", "SA80", "ASVal", "StG44" } },
	{ table = "Range_Armory_Battle", weapons = { "GE3", "BAR", "Lewis", "DC15S" } },
	{ table = "Range_Armory_Snipers", weapons = { "AWP", "M1Garand" } },
}
local TABLE_LENGTH = 210
-- A weapon dropped further than this from its table goes back on it at the next refill
local WEAPON_REACH = 400
-- Only things that would really blow up: metal drums, propane tanks and gas canisters
local BARREL_ASSETS = { "nanos-world::SM_Barrel_01", "nanos-world::SM_PropaneTank_01", "nanos-world::SM_TallGasCanister_01", "nanos-world::SM_PropaneTank_02", "nanos-world::SM_Canister" }
local BARREL_RESPAWN = 15000
local GRENADES = 4

-- The targets of the short and long ranges (range.py "Range_<Range>_Lane<i>_R<row>_C<column>" spots, the same targets in every lane): Sandbox Target's stand
-- and plate (SM_PG_TargetBase, SM_PG_<Style>_Plate) held still, the plate hinged HINGE_Z over the stand's pivot and swinging about its local X: flat away
-- from the shooters when down, upright when up. Outside a game one target of each column of a lane stands, at random; a shot one falls and IDLE_RISE ms
-- later one of its column stands up again
local HINGE_Z = 5
local FALL = { { -55, 0.08 }, { -85, 0.07 }, { -76, 0.08 }, { -85, 0.08 } }
local DROP = { { -85, 0.25 } }
local RISE = { { 6, 0.25 }, { -3, 0.12 }, { 0, 0.1 } }
local IDLE_RISE = 3000
local CLANG = "nanos-world::A_Metal_Clang"
local CLANG_FALLOFF = 12000
-- The referee's whistle from the range's board: once when a round starts, twice when it ends, WHISTLE_GAP ms apart
local WHISTLE = "nanos-world::A_Referee_Whistle"
local WHISTLE_FALLOFF, WHISTLE_VOLUME = 6000, 0.5
local WHISTLE_GAP = 450

-- The shooting game: the range's button (range.py "Range_<Range>_Start") starts a round of GAME_TIME seconds after a short countdown, in which targets pop up
-- and go down again by themselves, and every lane scores the targets it knocks down while they are up. Every lane gets as many targets up at the same time,
-- each lane its own at random; as the round goes on more come up at once (GAME_UP_COUNT, from the start to the end) and they stay up and pause for less.
-- The board beside the range (range.py "Range_<Range>_Board") shows the time left, each lane's score and the winner. Per range, how long targets stay up and
-- the pause before the next ones (s, at the start and at the end), as range.py RANGES' names
local GAME_TIME = 60
local GAME_COUNTDOWN = 3
local GAME_UP_COUNT = { 1, 3 }
local GAME_PACE = { Short = { up = { 1.8, 0.8 }, gap = { 0.6, 0.25 } }, Long = { up = { 2.8, 1.4 }, gap = { 0.8, 0.35 } } }
local GAME_TITLE = { Short = "SHORT RANGE", Long = "LONG RANGE" }
-- On the board, in the panel's cm: the title, the clock line and one row per lane (label and score)
local BOARD_TITLE_Z, BOARD_CLOCK_Z, BOARD_ROW_Z, BOARD_ROW_STEP = 320, 265, 205, 50
local BOARD_LABEL_X, BOARD_SCORE_X = -70, 110
local BOARD_INK = Color(0, 0, 0)

-- Things to shoot on the construction props (range.py "Range_Shoot_*" markers): asset and the pieces it breaks into (asset, offset, rotation), spawned again a while after
local SHOOTABLES = {
	{ "nanos-world::SM_Fruit_Watermelon_01", { { "nanos-world::SM_Fruit_Watermelon_01_Half_01", Vector(0, -10, 5), Rotator(0, 0, 90) }, { "nanos-world::SM_Fruit_Watermelon_01_Half_01", Vector(0, 10, 5), Rotator(0, 0, -90) }, { "nanos-world::SM_Fruit_Watermelon_01_Slice_01", Vector(0, 0, 15), Rotator() } } },
	{ "nanos-world::SM_Fruit_Cantaloupe_01", { { "nanos-world::SM_Fruit_Cantaloupe_01_Half_01", Vector(0, -6, 4), Rotator(0, 0, 90) }, { "nanos-world::SM_Fruit_Cantaloupe_01_Half_01", Vector(0, 6, 4), Rotator(0, 0, -90) } } },
	{ "nanos-world::SM_Bottle_01", {} },
	{ "nanos-world::SM_Bottle_02", {} },
}
-- Pumpkins are kept for Halloween
if (Playground.theme == "halloween") then table.insert(SHOOTABLES, { "nanos-world::SM_Fruit_Pumpkin_01", {} }) end
local SHOOTABLE_RESPAWN = 6000
local PIECE_LIFESPAN = 8

local function SpawnShootable(spot)
	local item = SHOOTABLES[math.random(#SHOOTABLES)]
	local prop = Playground.Track(Prop(spot.location + Vector(0, 0, 2), Rotator(0, math.random(0, 359), 0), item[1], CollisionType.Normal, true, GrabMode.Enabled))
	-- They break into their own pieces with a +1 below, whether Sandbox knows the mesh or not
	prop:SetValue("Unbreakable", true)
	prop:Subscribe("TakeDamage", function(self)
		if (self.broken) then return false end
		self.broken = true
		local location, yaw = self:GetLocation(), self:GetRotation().Yaw
		Playground.ScorePop(location + Vector(0, 0, 30))
		self:Destroy()
		for _, piece in ipairs(item[2]) do
			local turn = Rotator(0, yaw, 0)
			local part = Prop(location + turn:RotateVector(piece[2]), Rotator(piece[3].Pitch, yaw + piece[3].Yaw, piece[3].Roll), piece[1], CollisionType.Normal, true, GrabMode.Enabled)
			part:SetLifeSpan(PIECE_LIFESPAN)
		end
		Timer.SetTimeout(function()
			if (Playground.spawned) then SpawnShootable(spot) end
		end, SHOOTABLE_RESPAWN)
		return false
	end)
	return prop
end

-- An explosive at location: Sandbox blows it up (the drums at once, the tanks after leaking and burning a few seconds); a while after it is gone,
-- spawn puts a new one in its place
local function SpawnExplosive(location, rotation, asset, spawn)
	local barrel = Prop(location, rotation, asset, CollisionType.Normal, true, GrabMode.Enabled)
	barrel:Subscribe("Destroy", function()
		Timer.SetTimeout(function()
			if (Playground.spawned) then spawn() end
		end, BARREL_RESPAWN)
	end)
	return Playground.Track(barrel)
end

local function SpawnBarrel(spot, index)
	SpawnExplosive(spot.location + Vector(0, 0, 5), Rotator(0, index * 37, 0), BARREL_ASSETS[(index - 1) % #BARREL_ASSETS + 1], function() SpawnBarrel(spot, index) end)
end

-- Steps a plate through frames (relative roll, seconds) one after the other, then calls done; a new animation cancels the one running
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

	target.plate:RotateRelativeTo(Rotator(0, 0, frame[1]), frame[2])
	Timer.SetTimeout(function()
		if (target.animation == animation) then Animate(target, frames, done, index + 1) end
	end, math.floor(frame[2] * 1000))
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
	Animate(target, up and RISE or DROP)
end

local function KnockDown(target)
	target.up = false
	Animate(target, FALL)
	Playground.PlaySound(target.top, CLANG, CLANG_FALLOFF)
	Playground.ScorePop(target.top + Vector(0, 0, 20))
end

-- A range of the game: its lanes (each its targets, by index, and score), its board texts and the round running on it
local function Board(game)
	local spot = game.board
	if (not spot) then return end
	game.texts = {
		clock = Playground.BoardText(spot, 0, BOARD_CLOCK_Z, "READY", 34, BOARD_INK),
		scores = {},
	}
	Playground.BoardText(spot, 0, BOARD_TITLE_Z, GAME_TITLE[game.name] or game.name, 42, BOARD_INK)
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

-- The same number of targets up in every lane (each lane's own, at random) for the range's pace at this point of the round, then down if still up, then
-- the next ones after a pause
local function Pop(game, round)
	if (game.round ~= round or not Playground.spawned) then return end
	local pace = GAME_PACE[game.name] or GAME_PACE.Short
	local t = math.min(1, math.max(0, (Server.GetTime() - game.started) / (GAME_TIME * 1000)))
	local count = math.min(GAME_UP_COUNT[2], math.floor(Lerp({ GAME_UP_COUNT[1], GAME_UP_COUNT[2] + 1 }, t)))

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
		Timer.SetTimeout(function() Pop(game, round) end, math.floor(Lerp(pace.gap, t) * 1000))
	end, math.floor(Lerp(pace.up, t) * 1000))
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
		Timer.SetTimeout(function() Playground.PlaySound(location, WHISTLE, WHISTLE_FALLOFF, WHISTLE_VOLUME) end, k * WHISTLE_GAP + 1)
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
	local left = GAME_COUNTDOWN
	local ticker
	ticker = Timer.SetInterval(function()
		if (game.round ~= round or not Playground.spawned) then
			Timer.ClearInterval(ticker)
			return
		end
		if (left > 0) then
			Show(game, "GET READY  " .. left)
		elseif (left == 0) then
			Show(game, Clock(GAME_TIME))
			game.started = Server.GetTime()
			Whistle(game, 1)
			Pop(game, round)
		elseif (-left >= GAME_TIME) then
			Timer.ClearInterval(ticker)
			Finish(game, round)
			return
		else
			Show(game, Clock(GAME_TIME + left))
		end
		left = left - 1
	end, 1000)
	Show(game, "GET READY  " .. left)
	left = left - 1
end

local function SpawnGame(name, spots)
	local game = { name = name, lanes = {}, running = false, board = Playground.Spot("Range_" .. name .. "_Board") }
	for _, entry in ipairs(spots) do
		local lane_index, column_index = entry.name:match("_Lane(%d+)_R%d+_C(%d+)$")
		if (lane_index) then
			lane_index, column_index = tonumber(lane_index) + 1, tonumber(column_index) + 1
			game.lanes[lane_index] = game.lanes[lane_index] or { targets = {}, columns = {}, score = 0 }
			local lane = game.lanes[lane_index]
			local target = SpawnTarget(entry.spot)
			lane.targets[#lane.targets + 1] = target
			lane.columns[column_index] = lane.columns[column_index] or {}
			local column = lane.columns[column_index]
			column[#column + 1] = target

			target.plate:Subscribe("TakeDamage", function()
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
					end, IDLE_RISE)
				end
				return false
			end)
		end
	end
	Idle(game)

	-- The button starts a round, Sandbox's LogicButton (shooting it starts one too)
	local start = Playground.Spot("Range_" .. name .. "_Start")
	if (start and Playground.HasSandbox()) then
		Board(game)
		Playground.Button(Playground.Top(start, 0), Rotator(0, start.rotation.Yaw, 0), "start", "start", function() Start(game) end, nil, false, "PushButton")
	end
end

Playground.Setup("Range", function()
	if (not NanosWorldWeapons) then
		Console.Warn("Playground: default-weapons not loaded, the armory stays empty")
	else
		for _, group in ipairs(ARMORY) do
			local spot = Playground.Spot(group.table)

			if (spot) then
				local step = TABLE_LENGTH / #group.weapons

				for i, name in ipairs(group.weapons) do
					local class = NanosWorldWeapons[name]

					if (class) then
						-- Side by side along the table (its local X), lying on their side, grips towards the visitor at the front (local +Y) and muzzles to the back; the grip pivot sits behind the gun's middle
						local along = (i - (#group.weapons + 1) / 2) * step
						local location = Playground.At(spot, along, 15, spot.top + 6)
						local rotation = Rotator(0, spot.rotation.Yaw - 90, 90)

						-- Melees the same way round, centred on the table (their pivot is the handle's end)
						if (group.table == "Range_Armory_Melee") then
							location, rotation = Playground.LyingMelee(name, Playground.At(spot, along, 0, spot.top), spot.rotation.Yaw)
						end

						Playground.ReturningSlot(function() return class(location, rotation) end, WEAPON_REACH)
					end
				end
			end
		end
	end

	-- Grenades on the throwing wall
	local wall = Playground.Spot("Range_Grenade_Throw")
	for i = 1, GRENADES do
		local location = wall and Playground.At(wall, 0, (i - (GRENADES + 1) / 2) * 60, 120)

		if (location) then
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
