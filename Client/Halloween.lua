-- Halloween sky, while the server's theme is on (Server/Index.lua "Playground.Theme" value is "halloween"): a huge orange full moon and orange moonlight, day and night still turning as usual
-- Sandbox owns the sky and sets it up again whenever it spawns it for this player, so this goes on top a moment after that, and once now for a sky already there
-- The sky only takes some of these (the moon's material color) when it is rebuilt, hence the Reconstruct after them

local MOON_COLOR = Color(1, 0.42, 0.1)
local MOON_LIGHT_COLOR = Color(1, 0.5, 0.2)
local MOON_PHASE = 15                  -- full (0-30)
local MOON_SCALE = 8
local MOON_GLOW = 3
local MOON_LIGHT = 3
local NIGHT_BRIGHTNESS = 1.5
-- Sandbox's SpawnSky handler may run after this one
local AFTER_SANDBOX = 1000

local function Apply()
	if (Client.GetValue("Playground.Theme") ~= "halloween" or not Sky.IsSpawned(false)) then return end
	Sky.SetMoonMaterialColor(MOON_COLOR)
	Sky.SetMoonLightColor(MOON_LIGHT_COLOR)
	Sky.SetMoonPhase(MOON_PHASE)
	Sky.SetMoonScale(MOON_SCALE)
	Sky.SetMoonGlowIntensity(MOON_GLOW)
	Sky.SetMoonLightIntensity(MOON_LIGHT)
	Sky.SetNightBrightness(NIGHT_BRIGHTNESS)
	Sky.Reconstruct()
end

Events.SubscribeRemote("SpawnSky", function()
	Timer.SetTimeout(Apply, AFTER_SANDBOX)
end)

Apply()
