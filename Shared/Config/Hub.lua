-- Buttons of the hub's time and weather panel: the server spawns them, the client writes their labels; row 1 sets the time of day, row 2 the weather
HUB_SKY_BUTTONS = {
	{
		label = "Morning",
		row = 1,
		hours = 8,
		minutes = 0
	},
	{
		label = "Noon",
		row = 1,
		hours = 12,
		minutes = 0
	},
	{
		label = "Sunset",
		row = 1,
		hours = 18,
		minutes = 30
	},
	{
		label = "Night",
		row = 1,
		hours = 23,
		minutes = 0
	},
	{
		label = "Clear",
		row = 2,
		weather = WeatherType.ClearSkies
	},
	{
		label = "Partly",
		row = 2,
		weather = WeatherType.PartlyCloudy
	},
	{
		label = "Cloudy",
		row = 2,
		weather = WeatherType.Cloudy
	},
	{
		label = "Fog",
		row = 2,
		weather = WeatherType.Foggy
	},
	{
		label = "Rain",
		row = 2,
		weather = WeatherType.Rain
	},
	{
		label = "Storm",
		row = 2,
		weather = WeatherType.RainThunderstorm
	},
	{
		label = "Snow",
		row = 2,
		weather = WeatherType.Snow
	}
}

-- Each row's button height on the panel face, from the panel's base
HUB_SKY_ROW_Z = { 125, 50 }

-- Distance between two buttons of a row
HUB_SKY_BUTTON_STEP = 56
