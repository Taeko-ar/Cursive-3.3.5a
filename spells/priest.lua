local L = AceLibrary("AceLocale-2.2"):new("Cursive")
function getPriestSpells()
	return {
		[L["shackle undead"]] = { duration = 50 },
		[L["mind soothe"]] = { duration = 15 },
		[L["mind control"]] = { duration = 60 },
		[L["devouring plague"]] = { duration = 24 },
		[L["shadow word: pain"]] = { duration = 18 },
		[L["vampiric embrace"]] = { duration = 60 },
		[L["burning zeal"]] = { duration = 18 },
		[L["holy fire"]] = { duration = 10 },
	}
end
