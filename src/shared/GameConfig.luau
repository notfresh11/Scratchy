local GameConfig = {}

GameConfig.Tickets = {
	["Simple"] = {
		Cost = 100,
		WinChancePerSquare = 0.35, -- 35%
		Rewards = {
			Jackpot = 500, -- 3 matches
			Medium = 150,  -- 2 matches
		}
	},
	["Rare"] = {
		Cost = 250,
		WinChancePerSquare = 0.40, -- 40%
		Rewards = {
			Jackpot = 1500, -- 3 matches
			Medium = 400,   -- 2 matches
		}
	},
	["Golden"] = {
		Cost = 500,
		WinChancePerSquare = 0.45, -- 45%
		Rewards = {
			Jackpot = 4000, -- 3 matches
			Medium = 800,   -- 2 matches
		}
	}
}

GameConfig.StartingCash = 1000

return GameConfig
