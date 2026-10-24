-- A physics prop dragged further than this from its spot is put back on the next refill
PROPS_REACH = 2500

-- Exhibits are dropped from this high above their stand's top, so they settle on it instead of starting inside it
PROPS_EXHIBIT_LIFT = 15

-- An exhibit carried further than this from its stand is put back on it on the next refill
PROPS_EXHIBIT_REACH = 600

-- Light circuit dressing by mesh (kg): a car pushes a cone or tyre aside instead of riding up on it and getting stuck (the mass from the mesh's volume was heavy enough to wedge under a car); a few kg, not less, or the car to prop mass ratio makes the physics jitter
PROPS_MASS = {
	["nanos-world::SM_ConstructionPylons_05"] = 4,
	["nanos-world::SM_TireLarge"] = 12
}

-- Museum props held still instead of dropped (a melon rolls off-centre): how high their pivot sits above what they rest on
PROPS_MUSEUM_STILL = {
	["nanos-world::SM_Fruit_Watermelon_01"] = 14
}

-- Museum entities laid on their side (their LYING_SHAPES) and held there, gravity off: their spot is where the middle of the gun lies on the case floor
PROPS_MUSEUM_LYING = {
	WeldGun = true,
	PhysicsGun = true
}
