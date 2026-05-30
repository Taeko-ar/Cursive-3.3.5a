local L = AceLibrary("AceLocale-2.2"):new("Cursive")
function getHunterSpells()
	return {
		[L["scorpid sting"]] = { duration = 20 },
		[L["serpent sting"]] = { duration = 15 },
		[L["viper sting"]] = { duration = 8 },
		[L["wyvern sting"]] = { duration = 30 },
		[L["wing clip"]] = { duration = 10 },
		[L["concussive shot"]] = { duration = 4 },
		[L["counterattack"]] = { duration = 5 },
		[L["hunter's mark"]] = { duration = 300 },
	}
end
