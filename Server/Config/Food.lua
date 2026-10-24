-- Food laid on the picnic tables, a new pick at each refill: fruit, pizza and bread that break apart like Sandbox's breakables
FOOD_ASSETS = {
	"nanos-world::SM_Fruit_Watermelon_01",
	"nanos-world::SM_Fruit_Cantaloupe_01",
	"nanos-world::SM_Fruit_Apple_Red_01",
	"nanos-world::SM_Fruit_Apple_Green_01",
	"nanos-world::SM_Fruit_Orange_01",
	"nanos-world::SM_Fruit_Pear_01",
	"nanos-world::SM_Fruit_Peach_01",
	"nanos-world::SM_Fruit_Mango_01",
	"nanos-world::SM_Fruit_Lemon_01",
	"nanos-world::SM_Fruit_Avocado_01",
	"nanos-world::SM_Bread_Pizza_01",
	"nanos-world::SM_Bread_Loaf_Multi_01"
}

-- Places along a table's length (its local X: SM_PG_Picnic is 180 long), one pick each
FOOD_PLACES = { -60, 0, 60 }

-- The lake's table has its jukebox in the middle, so only its ends get food
FOOD_JUKEBOX_PLACES = { -65, 65 }

-- Food carried further than this from its table is put back on the next refill
FOOD_REACH = 600
