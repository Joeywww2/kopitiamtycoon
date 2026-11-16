--!strict
-- Ringgit as players read it: RM 950, RM 1,250, RM 12.5K, RM 3.20M.
local Format = {}

local function commas(n: number): string
	local digits = tostring(math.floor(n))
	local out = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then
		out = out:sub(2)
	end
	return out
end

function Format.money(amount: number): string
	local n = math.max(0, math.floor(amount))
	if n < 10000 then
		return "RM " .. commas(n)
	elseif n < 1000000 then
		return string.format("RM %.1fK", n / 1000)
	elseif n < 1000000000 then
		return string.format("RM %.2fM", n / 1000000)
	end
	return string.format("RM %.2fB", n / 1000000000)
end

return Format
