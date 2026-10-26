-- A physics prop moved further than this from its spot is put back on the next refill
PROPS_REACH = 100

-- Exhibits are dropped from this high above their stand's top, so they settle on it instead of starting inside it
PROPS_EXHIBIT_LIFT = 15

-- An exhibit carried further than this from its stand is put back on it on the next refill
PROPS_EXHIBIT_REACH = 100

-- Circuit dressing by mesh that vehicles push aside without feeling it, their wheels driving through instead of climbing it (Prop:SetOneWayInteraction)
PROPS_ONE_WAY = {
	["nanos-world::SM_ConstructionPylons_05"] = true,
	["nanos-world::SM_TireLarge"] = true
}

-- Exhibit props held still, gravity off, instead of dropped (a melon rolls off-centre, Tung Tung Tung Sahur slid off its uneven spot and kept respawning): how high their pivot sits above their spot's top
PROPS_STILL = {
	["nanos-world::SM_Fruit_Watermelon_01"] = 14,
	["nanos-world::SM_TungTungTungSahur"] = 0
}

-- Museum entities laid on their side (their LYING_SHAPES) and held there, gravity off: their spot is where the middle of the gun lies on the case floor
PROPS_MUSEUM_LYING = {
	WeldGun = true,
	PhysicsGun = true
}
