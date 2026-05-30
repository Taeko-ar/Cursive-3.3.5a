local L = AceLibrary("AceLocale-2.2"):new("Cursive")
function getMageSpells()
	return {
		[L["polymorph"]] = { duration = 50 },
		[L["polymorph: cow"]] = { duration = 50 },
		[L["polymorph: turtle"]] = { duration = 50 },
		[L["polymorph: pig"]] = { duration = 50 },
		["living bomb"] = { duration = 12 },
	}
end
