local L = AceLibrary("AceLocale-2.2"):new("Cursive")
function getDruidSpells()
	return {
		[L["entangling roots"]] = { duration = 30 },
		[L["sleep"]] = { duration = 40 }, -- Hibernate
		[L["faerie fire"]] = { duration = 300 },
		[L["hibernate"]] = { duration = 40 },
		[L["insect swarm"]] = { duration = 12 },
		[L["moonfire"]] = { duration = 12 },
		[L["rake"]] = { duration = 9, meleeBleed = true },
		[L["rip"]] = { duration = 12 },
		[L["soothe animal"]] = { duration = 15 },
		[L["bash"]] = { duration = 4 },
		[L["demoralizing roar"]] = { duration = 30 },
		[L["challenging roar"]] = { duration = 6 },
		[L["pounce bleed"]] = { duration = 18, meleeBleed = true },
		["lacerate"] = { duration = 15, meleeBleed = true },
	}
end
