local L = AceLibrary("AceLocale-2.2"):new("Cursive")
function getWarlockSpells()
	return {
		[L["corruption"]] = { duration = 18, darkHarvest = true, numTicks = 6 },
		[L["curse of agony"]] = { duration = 24, darkHarvest = true, numTicks = 12 },
		[L["siphon life"]] = { duration = 30, darkHarvest = true, numTicks = 10 }, -- Supported for compatibility
		[L["curse of doom"]] = { duration = 60 },
		[L["curse of the elements"]] = { duration = 300 },
		[L["curse of tongues"]] = { duration = 30 },
		[L["curse of weakness"]] = { duration = 120 },
		[L["curse of exhaustion"]] = { duration = 12 },
		[L["immolate"]] = { duration = 15 },
		[L["unstable affliction"]] = { duration = 15 },
		[L["haunt"]] = { duration = 12 },
		[L["seed of corruption"]] = { duration = 18 },
		[L["death coil"]] = { duration = 3, travelTime = true },
		[L["banish"]] = { duration = 30 },
		[L["fear"]] = { duration = 20 },
	}
end
