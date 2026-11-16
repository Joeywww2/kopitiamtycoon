--!strict
-- Everything a player can buy, in the order it unlocks.
--   price     ringgit to buy it
--   income    ringgit a second it adds
--   requires  ids that must be owned before its buy pad appears
--   kind      which model the server builds (see server/Models)
--   x, z      where it stands on the plot. The middle is 0,0; +z is the front, facing the plaza.
--   y         height off the floor, for things on walls or the ceiling
--   padX/padZ where its buy pad sits, when the default (just in front of it) would not work

export type Item = {
	id: string,
	name: string,
	price: number,
	income: number,
	requires: { string },
	kind: string,
	x: number,
	z: number,
	y: number?,
	padX: number?,
	padZ: number?,
	autoCollect: boolean?,
	unlocksBranch: boolean?,
}

local items: { Item } = {
	-- One kopi stall
	{ id = "kopi_stall", name = "Kopi Stall", price = 0, income = 1, requires = {}, kind = "stall", x = 0, z = -24 },
	{ id = "table_1", name = "Marble Table", price = 25, income = 1, requires = { "kopi_stall" }, kind = "table", x = -12, z = 0 },
	{ id = "roti_bakar", name = "Roti Bakar Toaster", price = 60, income = 2, requires = { "table_1" }, kind = "toaster", x = -12, z = -24 },
	{ id = "half_boiled", name = "Half-Boiled Eggs", price = 120, income = 3, requires = { "roti_bakar" }, kind = "eggs", x = 12, z = -24 },
	{ id = "table_2", name = "Second Table", price = 200, income = 3, requires = { "half_boiled" }, kind = "table", x = 12, z = 0 },
	{ id = "teh_tarik", name = "Teh Tarik Station", price = 350, income = 6, requires = { "table_2" }, kind = "tehtarik", x = -24, z = -24 },
	{ id = "walls", name = "Shop Walls", price = 500, income = 4, requires = { "teh_tarik" }, kind = "walls", x = 0, z = 0, padX = -24, padZ = 24 },
	{ id = "ceiling_fan", name = "Ceiling Fans", price = 800, income = 8, requires = { "walls" }, kind = "fans", x = 0, z = 0, y = 15, padX = 0, padZ = 6 },

	-- A proper hawker centre
	{ id = "nasi_lemak", name = "Nasi Lemak Stall", price = 1500, income = 15, requires = { "ceiling_fan" }, kind = "stall", x = 24, z = -24 },
	{ id = "char_kuey_teow", name = "Char Kuey Teow Wok", price = 2800, income = 25, requires = { "nasi_lemak" }, kind = "wok", x = -24, z = -12 },
	{ id = "kaya_shelf", name = "Homemade Kaya Shelf", price = 4500, income = 35, requires = { "char_kuey_teow" }, kind = "shelf", x = 24, z = -12 },
	{ id = "helper", name = "Hire Ah Boy (collects the till)", price = 6000, income = 0, requires = { "kaya_shelf" }, kind = "helper", x = 7, z = 22, padX = 14, padZ = 24, autoCollect = true },
	{ id = "satay", name = "Satay Grill", price = 9000, income = 60, requires = { "kaya_shelf" }, kind = "grill", x = -24, z = 0 },
	{ id = "cendol", name = "Cendol Cart", price = 15000, income = 90, requires = { "satay" }, kind = "cart", x = 24, z = 0 },

	-- The mamak corner
	{ id = "roti_canai", name = "Roti Canai Griddle", price = 25000, income = 140, requires = { "cendol" }, kind = "griddle", x = -24, z = 12 },
	{ id = "maggi_goreng", name = "Maggi Goreng Wok", price = 40000, income = 210, requires = { "roti_canai" }, kind = "wok", x = 24, z = 12 },
	{ id = "tv", name = "Football on TV", price = 65000, income = 320, requires = { "maggi_goreng" }, kind = "tv", x = 0, z = -30.5, y = 11, padX = 0, padZ = -12 },
	{ id = "neon_sign", name = "Neon Signboard", price = 100000, income = 480, requires = { "tv" }, kind = "neon", x = 0, z = 32, y = 16.9, padX = -12, padZ = 24 },

	-- Famous in the whole town
	{ id = "durian", name = "Durian Stall", price = 170000, income = 750, requires = { "neon_sign" }, kind = "durian", x = -12, z = 12 },
	{ id = "aircon", name = "Air-Cond", price = 280000, income = 1150, requires = { "durian" }, kind = "aircon", x = 0, z = 0, y = 11, padX = 0, padZ = -5 },
	{ id = "pasar_malam", name = "Pasar Malam Lot", price = 450000, income = 1800, requires = { "aircon" }, kind = "tent", x = 12, z = 12 },
	{ id = "delivery", name = "Delivery Riders", price = 750000, income = 2800, requires = { "pasar_malam" }, kind = "riders", x = 22, z = 37, padX = 24, padZ = 24 },
	{ id = "franchise", name = "Franchise Licence", price = 1200000, income = 4500, requires = { "delivery" }, kind = "plaque", x = 0, z = 13, padX = 0, padZ = 18, unlocksBranch = true },
}

local byId: { [string]: Item } = {}
for _, item in items do
	byId[item.id] = item
end

return {
	items = items,
	byId = byId,
	starter = "kopi_stall", -- every new kopitiam gets this for free
}
