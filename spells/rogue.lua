local L = AceLibrary("AceLocale-2.2"):new("Cursive")

local function getRuptureDuration()
	local cp = GetComboPoints("player", "target")
	if cp == 0 then cp = Cursive.curses.comboPoints or 5 end
	return 4 + cp * 4
end

local function getKidneyShotDuration()
	local cp = GetComboPoints("player", "target")
	if cp == 0 then cp = Cursive.curses.comboPoints or 5 end
	return 1 + cp
end

function getRogueSpells()
	return {
		[L["blind"]] = { duration = 60 },
		[L["sap"]] = { duration = 60 },
		[L["gouge"]] = { duration = 4 },
		[L["rupture"]] = { duration = 16, calculateDuration = getRuptureDuration, meleeBleed = true },
		[L["kidney shot"]] = { duration = 4, calculateDuration = getKidneyShotDuration },
		[L["expose armor"]] = { duration = 30 },
		[L["garrote"]] = { duration = 18, meleeBleed = true },
		[L["deadly poison"]] = { duration = 12 },
		[L["cheap shot"]] = { duration = 4 },
	}
end
