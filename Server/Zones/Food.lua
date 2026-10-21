-- Food on the picnic tables (export_spots.py TABLES, and the lake's table around its jukebox): fruit, pizza and bread that break apart like Sandbox's
-- breakables when they are hit, thrown or shot (Sandbox breaks every prop of its breakable meshes). A new pick lands on the table at each refill

local FOODS = {
	"nanos-world::SM_Fruit_Watermelon_01", "nanos-world::SM_Fruit_Cantaloupe_01", "nanos-world::SM_Fruit_Apple_Red_01", "nanos-world::SM_Fruit_Apple_Green_01",
	"nanos-world::SM_Fruit_Orange_01", "nanos-world::SM_Fruit_Pear_01", "nanos-world::SM_Fruit_Peach_01", "nanos-world::SM_Fruit_Mango_01",
	"nanos-world::SM_Fruit_Lemon_01", "nanos-world::SM_Fruit_Avocado_01", "nanos-world::SM_Bread_Pizza_01", "nanos-world::SM_Bread_Loaf_Multi_01",
}
-- Places along a table's length (its local X: SM_PG_Picnic is 180 long), one pick each; the jukebox stands in the middle of the lake's table
local PLACES = { -60, 0, 60 }
local JUKEBOX_PLACES = { -65, 65 }
local FOOD_REACH = 600

local function SetTable(location, rotation, top, places)
	for _, x in ipairs(places) do
		local at = location + rotation:RotateVector(Vector(x, math.random(-15, 15), top + 3))
		Playground.ReturningSlot(function()
			return Prop(at, Rotator(0, math.random(0, 359), 0), FOODS[math.random(#FOODS)], CollisionType.Normal, true, GrabMode.Enabled)
		end, FOOD_REACH)
	end
end

Playground.Setup("Food", function()
	for _, picnic in ipairs(TABLES or {}) do
		SetTable(picnic.location, picnic.rotation, picnic.top, PLACES)
	end

	for name, spot in pairs(SPOTS) do
		if (spot.mesh == "Picnic" and name:sub(-8) == "_Jukebox") then
			SetTable(spot.location, Rotator(0, spot.rotation.Yaw, 0), spot.top, JUKEBOX_PLACES)
		end
	end
end)
