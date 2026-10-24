-- The street lamps' light: warm sodium-like yellow, dim enough not to wash out the ground (HALLOWEEN_LAMP_COLOR while Halloween is on)
STREET_LAMP_COLOR = Color(1, 0.7, 0.3)

-- A wide cone down from the head, reaching far (cm), culled past its draw distance from the camera; no shadows, the most expensive part of a light
STREET_LAMP_LIGHT = {
	intensity = 20,
	radius = 2000,
	cone = 80,
	inner_cone = 20,
	draw_distance = 7000
}

-- The lens's emissive (MI_Plastic_IlluMI_On's Illum_Intensity, 0.1 by default) while lit
STREET_LAMP_LENS_GLOW = 20
