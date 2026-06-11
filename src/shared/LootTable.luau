local LootTable = {}

-- Definition of the 3 scratch card tiers
LootTable.Tiers = {
	["Carton"] = {
		Cost = 10,
		Rewards = {
			{Amount = 0, Weight = 50},
			{Amount = 5, Weight = 20},
			{Amount = 10, Weight = 15},
			{Amount = 20, Weight = 10},
			{Amount = 50, Weight = 5},
		}
	},
	["Argint"] = {
		Cost = 100,
		Rewards = {
			{Amount = 0, Weight = 45},
			{Amount = 50, Weight = 25},
			{Amount = 100, Weight = 15},
			{Amount = 200, Weight = 10},
			{Amount = 500, Weight = 5},
		}
	},
	["Aur"] = {
		Cost = 1000,
		Rewards = {
			{Amount = 0, Weight = 40},
			{Amount = 500, Weight = 30},
			{Amount = 1000, Weight = 15},
			{Amount = 2000, Weight = 10},
			{Amount = 10000, Weight = 5}, -- The Jackpot
		}
	}
}

-- Returns a random reward amount based on the tier's weights
function LootTable.Roll(tierName: string): number?
	local tier = LootTable.Tiers[tierName]
	if not tier then
		warn("Tier " .. tostring(tierName) .. " does not exist in LootTable")
		return nil
	end

	local totalWeight = 0
	for _, reward in ipairs(tier.Rewards) do
		totalWeight += reward.Weight
	end

	local randomValue = math.random(1, totalWeight)
	local currentWeight = 0

	for _, reward in ipairs(tier.Rewards) do
		currentWeight += reward.Weight
		if randomValue <= currentWeight then
			return reward.Amount
		end
	end

	return 0
end

return LootTable
