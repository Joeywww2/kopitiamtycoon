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

	AutosaveSeconds = 90,
	StartCash = 0,
}
