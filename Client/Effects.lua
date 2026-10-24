-- Sounds and effects only the clients play: the fountain's water, the tower's fireworks and lift music, and one-shot sounds the server asks for

-- The fountain's running water (its particle comes from the server, Server/Zones/Hub.lua): full volume within 1.5 m, silent past 9 m
local FOUNTAIN_VOLUME = 0.2

-- Lift music: plays on the lookout tower's cage while it rides (Server/Zones/Physics.lua), fading out as it arrives; heard from inside the cage and just around it, full volume within the inner radius, gone at the falloff distance
local LIFT_MUSIC = "nanos-world::A_LocalForecast"
local LIFT_MUSIC_VOLUME = 0.3
local LIFT_MUSIC_FADE = 1.5
local LIFT_MUSIC_INNER, LIFT_MUSIC_FALLOFF = 120, 700

function Playground.SpawnFountain()
	local spot = Playground.Spot("Hub_FountainWater")
	if (not spot) then return end

	Playground.Keep(Sound(spot.location, "nanos-world::A_Waterfall", false, false, SoundType.SFX, FOUNTAIN_VOLUME, 1, 150, 900, AttenuationFunction.NaturalSound, false, SoundLoopMode.Forever))
end

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
