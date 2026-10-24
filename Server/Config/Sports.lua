-- A ball further than this from its spot (nobody holding it) goes back at the next refill
SPORTS_BALL_REACH = 3000

-- A bell knocked further than this from its frame goes back at the next refill
SPORTS_BELL_REACH = 300

-- The referee's whistle when a ball goes out, and the crowd cheering a goal or a basket
SPORTS_WHISTLE = {
	asset = "nanos-world::A_Referee_Whistle",
	falloff = 5000,
	volume = 0.5
}

SPORTS_CHEER = {
	asset = "nanos-world::A_Applause",
	falloff = 6000,
	volume = 0.5
}

-- After a goal the ball (frozen in the net, nobody can kick or grab it) goes back on the centre spot this much later (ms), at rest
SPORTS_GOAL_RESET = 2500

-- The bells' notes from the visitor's left (local -X), each a little smaller than the one before (scale from the first to the last); their sounds are Client/Sounds/bell_<note>.ogg (sounds.py next to the props script)
SPORTS_BELL_NOTES = { "C5", "D5", "E5", "F5", "G5", "A5", "B5", "C6" }
SPORTS_BELL_SCALE = { 1.3, 0.8 }

SPORTS_BELL_SOUND = {
	path = "package://" .. Package.GetName() .. "/Client/Sounds/bell_",
	falloff = 4000,
	volume = 0.35
}

-- A ring swings the bell about the beam and back: each step's roll (degrees) and how long it takes (s); it takes no other ring for cooldown ms
SPORTS_BELL_SWING = {
	{
		roll = 16,
		time = 0.08
	},
	{
		roll = -10,
		time = 0.16
	},
	{
		roll = 5,
		time = 0.15
	},
	{
		roll = 0,
		time = 0.12
	}
}

SPORTS_BELL_COOLDOWN = 150
