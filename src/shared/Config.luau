--!strict
-- Tuning numbers for the whole game. Change them here, nowhere else.
return {
	DataStoreName = "KopitiamTycoon_v1",

	-- The map: plots sit in a ring around the plaza, each facing the middle.
	PlotCount = 6,
	PlotSize = 64,
	PlotRadius = 120,

	-- The till holds this many seconds of income before it is full (and never less than the minimum).
	TillSeconds = 300,
	TillMinimum = 50,

	-- Each new branch adds this much to the income multiplier (0.5 = +50%).
	BranchBonus = 0.5,

	-- Ah Ma's angpow: how often, and how many seconds of income it is worth.
	AngpowHours = 20,
	AngpowSeconds = 120,
	AngpowMinimum = 50,

	-- While a player is away, their kopitiam keeps earning this share of its income, for at most this long.
	OfflineShare = 0.5,
	OfflineHours = 8,
	OfflineMinimumSeconds = 120, -- shorter breaks earn nothing, so rejoining is not a trick

	-- Customers who walk in, order, and leave. Only for looks: income does not depend on them.
	CustomerMax = 6,
	CustomerEverySeconds = 4,
	CustomerWalkSpeed = 9, -- studs a second

	-- The Robux shop. Make each one in the Creator Hub (your game > Monetization), then paste its ID here.
	-- Anything left at 0 does not show in the shop, so the game works before any of them exist.
	GamePasses = {
		DoubleCash = 0, -- everything earns x2, forever
		AutoCollect = 0, -- the till empties itself from day one, without hiring Ah Boy
	},
	Products = { -- bought again and again; each gives this many seconds of the player's income, at least the minimum
		CashSmall = { id = 0, seconds = 900, minimum = 500 },
		CashBig = { id = 0, seconds = 7200, minimum = 5000 },
	},

	-- Sounds. Pick free ones in the Creator Store (Toolbox > Audio), copy the ID, and write "rbxassetid://ID".
	-- Anything left empty stays silent.
	Sounds = {
		Buy = "",
		Collect = "",
		Angpow = "",
		Branch = "",
		Music = "", -- plays on a loop, quietly
	},

	AutosaveSeconds = 90,
	StartCash = 0,
}
