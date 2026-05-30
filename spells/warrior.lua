local L = AceLibrary("AceLocale-2.2"):new("Cursive")
function getWarriorSpells()
	return {
		[L["rend"]] = { duration = 15, meleeBleed = true },
	}
end
