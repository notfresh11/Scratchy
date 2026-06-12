local GameConfig = {}

GameConfig.Tickets = {
	["Simple"] = {
		Cost = 100,
		WinChancePerSquare = 0.35, -- 35%
		Rewards = {
			Jackpot = 200, -- 3 matches: 2x Cost
			Medium = 150,  -- 2 matches: 1.5x Cost
		}
	},
	["Rare"] = {
		Cost = 250,
		WinChancePerSquare = 0.40, -- 40%
		Rewards = {
			Jackpot = 500, -- 3 matches: 2x Cost
			Medium = 375,  -- 2 matches: 1.5x Cost
		}
	},
	["Golden"] = {
		Cost = 500,
		WinChancePerSquare = 0.45, -- 45%
		Rewards = {
			Jackpot = 1000, -- 3 matches: 2x Cost
			Medium = 750,   -- 2 matches: 1.5x Cost
		}
	}
}

GameConfig.StartingCash = 1000

return GameConfig
