local L = AceLibrary("AceLocale-2.2"):new("Cursive")

local _, playerClassName = UnitClass("player")

local curses = {
	trackedSpells = {},
	trackedCurseNamesToTextures = {},
	conflagrateSpellIds = {
		[17962] = true,
		[18930] = true,
		[18931] = true,
		[18932] = true,
	},
	darkHarvestSpellIds = {
		[52550] = true,
		[52551] = true,
		[52552] = true,
	},
	darkHarvestData = {},
	guids = {},
	isChanneling = false,
	pendingCast = {},
	resistSoundGuids = {},
	expiringSoundGuids = {},
	requestedExpiringSoundGuids = {}, -- guid added on spellcast, moved to expiringSoundGuids once rendered by ui
	comboPoints = 0,
	lastFerociousBiteTime = 0,
	lastFerociousBiteTargetGuid = 0,
}

function curses:GetComboPointsUsed()
	return curses.comboPoints
end

function curses:LoadCurses()
	curses.trackedSpells = {}
	curses.trackedCurseNamesToTextures = {}

	curses.isWarlock = playerClassName == "WARLOCK"
	curses.isPriest = playerClassName == "PRIEST"
	curses.isMage = playerClassName == "MAGE"
	curses.isDruid = playerClassName == "DRUID"
	curses.isHunter = playerClassName == "HUNTER"
	curses.isRogue = playerClassName == "ROGUE"
	curses.isShaman = playerClassName == "SHAMAN"
	curses.isWarrior = playerClassName == "WARRIOR"

	-- Load class-specific spell lists
	if curses.isWarlock then
		curses.trackedSpells = getWarlockSpells()
	elseif curses.isPriest then
		curses.trackedSpells = getPriestSpells()
	elseif curses.isMage then
		curses.trackedSpells = getMageSpells()
	elseif curses.isDruid then
		curses.trackedSpells = getDruidSpells()
	elseif curses.isHunter then
		curses.trackedSpells = getHunterSpells()
	elseif curses.isRogue then
		curses.trackedSpells = getRogueSpells()
	elseif curses.isShaman then
		curses.trackedSpells = getShamanSpells()
	elseif curses.isWarrior then
		curses.trackedSpells = getWarriorSpells()
	end

	-- Resolve textures dynamically
	for name, data in pairs(curses.trackedSpells) do
		local _, _, texture = GetSpellInfo(name)
		if texture then
			data.texture = texture
			curses.trackedCurseNamesToTextures[name] = texture
		end
	end

	-- Register WotLK events
	Cursive:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function(event, ...)
		curses:OnCombatLogEvent(...)
	end)

	if curses.isDruid or curses.isRogue then
		Cursive:RegisterEvent("UNIT_COMBO_POINTS", function(event, unit)
			if unit == "player" then
				curses.comboPoints = GetComboPoints("player", "target")
			end
		end)
		Cursive:RegisterEvent("PLAYER_TARGET_CHANGED", function()
			curses.comboPoints = GetComboPoints("player", "target")
		end)
	end
end

function curses:OnCombatLogEvent(...)
	local timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, spellSchool, auraType, amount = ...

	-- Target / Unit Died
	if eventType == "UNIT_DIED" or eventType == "UNIT_DESTROYED" then
		curses:RemoveGuid(destGUID)
		Cursive.core.remove(destGUID)
		return
	end

	-- Check if player or player pet is source
	local isPlayer = (sourceGUID == UnitGUID("player"))
	local isPet = (sourceGUID == UnitGUID("pet"))
	local isCurrentPlayer = (isPlayer or isPet)

	-- Check if spell is tracked
	if not spellName then return end
	local lowercaseSpellName = string.lower(spellName)
	local trackData = curses.trackedSpells[lowercaseSpellName]

	if not trackData then return end

	-- Debuff Applied / Refreshed
	if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" then
		if auraType == "DEBUFF" then
			local isShared = (Cursive.db and Cursive.db.profile.shareddebuffs.faeriefire and lowercaseSpellName == L["faerie fire"])
			
			if isCurrentPlayer or isShared then
				local duration = trackData.duration
				if trackData.calculateDuration then
					duration = trackData.calculateDuration()
				end

				local startTime = GetTime()

				-- If we have a UnitToken, retrieve the exact duration/expiration time from the server
				local token = Cursive.core:GetTokenForGUID(destGUID)
				if token then
					local _, _, _, _, _, dur, expTime = UnitDebuff(token, spellName)
					if dur and dur > 0 then
						duration = dur
						startTime = expTime - dur
					end
				end

				curses:ApplyCurse(spellId, lowercaseSpellName, destGUID, startTime, duration, isCurrentPlayer)
			end
		end

	-- Debuff Removed
	elseif eventType == "SPELL_AURA_REMOVED" then
		if auraType == "DEBUFF" then
			curses:RemoveCurse(destGUID, lowercaseSpellName)
		end

	-- Spell Cast Successful (for tracking pending cast clearing)
	elseif eventType == "SPELL_CAST_SUCCESS" then
		if isCurrentPlayer then
			curses.pendingCast = {}
		end

	-- Spell Cast Start
	elseif eventType == "SPELL_CAST_START" then
		if isCurrentPlayer then
			curses.pendingCast = {
				spellName = lowercaseSpellName,
				targetGuid = destGUID,
				start = GetTime()
			}
		end

	-- Spell Missed / Resisted
	elseif eventType == "SPELL_MISSED" then
		if isCurrentPlayer then
			curses.pendingCast = {}
			local missType = auraType -- For SPELL_MISSED, the 15th param (auraType field in our unpack) is missType
			if missType == "RESIST" or missType == "IMMUNE" then
				if curses:ShouldPlayResistSound(destGUID) then
					PlaySoundFile("Interface\\AddOns\\Cursive\\Sounds\\resist.mp3")
				end
			end
		end
	end
end

function curses:GetLowercaseSpellName(spellName)
	spellName = string.lower(spellName)
	if curses.isDruid and string.find(spellName, L["faerie fire"]) then
		return L["faerie fire"]
	end
	return spellName
end

function curses:TimeRemaining(curseData)
	local remaining = curseData.duration - (GetTime() - curseData.start)
	if Cursive.db and Cursive.db.profile.curseshowdecimals and remaining < 10 then
		remaining = math.floor(remaining * 10) / 10
	else
		remaining = math.ceil(remaining)
	end
	return remaining
end

function curses:EnableResistSound(guid)
	curses.resistSoundGuids[guid] = true
end

function curses:EnableExpiringSound(lowercaseSpellNameNoRank, guid)
	if curses.requestedExpiringSoundGuids[guid] and curses.requestedExpiringSoundGuids[guid][lowercaseSpellNameNoRank] then
		curses.requestedExpiringSoundGuids[guid][lowercaseSpellNameNoRank] = nil
	end

	if not curses.expiringSoundGuids[guid] then
		curses.expiringSoundGuids[guid] = {}
	end
	curses.expiringSoundGuids[guid][lowercaseSpellNameNoRank] = true
end

function curses:RequestExpiringSound(lowercaseSpellNameNoRank, guid)
	if not curses.requestedExpiringSoundGuids[guid] then
		curses.requestedExpiringSoundGuids[guid] = {}
	end
	curses.requestedExpiringSoundGuids[guid][lowercaseSpellNameNoRank] = true
end

function curses:HasRequestedExpiringSound(lowercaseSpellNameNoRank, guid)
	return curses.requestedExpiringSoundGuids[guid] and curses.requestedExpiringSoundGuids[guid][lowercaseSpellNameNoRank]
end

function curses:ShouldPlayExpiringSound(lowercaseSpellNameNoRank, guid)
	if curses.expiringSoundGuids[guid] and curses.expiringSoundGuids[guid][lowercaseSpellNameNoRank] then
		curses.expiringSoundGuids[guid][lowercaseSpellNameNoRank] = nil
		return true
	end
	return false
end

function curses:ShouldPlayResistSound(guid)
	if curses.resistSoundGuids[guid] then
		curses.resistSoundGuids[guid] = nil
		return true
	end
	return false
end

function curses:HasAnyCurse(guid)
	if curses.guids[guid] and next(curses.guids[guid]) then
		return true
	end
	return nil
end

function curses:GetCurseData(spellName, guid)
	local lowercaseSpellNameNoRank = Cursive.utils.GetLowercaseSpellNameNoRank(spellName)
	if curses.guids[guid] and curses.guids[guid][lowercaseSpellNameNoRank] then
		return curses.guids[guid][lowercaseSpellNameNoRank]
	end
	return nil
end

function curses:HasCurse(lowercaseSpellNameNoRank, targetGuid, minRemaining, malediction)
	if not minRemaining then
		minRemaining = 0
	end

	lowercaseSpellNameNoRank = curses:GetLowercaseSpellName(lowercaseSpellNameNoRank)

	if curses.guids[targetGuid] and curses.guids[targetGuid][lowercaseSpellNameNoRank] then
		local remaining = curses:TimeRemaining(curses.guids[targetGuid][lowercaseSpellNameNoRank])
		if remaining >= minRemaining then
			return true
		end
	end

	-- Check pending cast
	if curses.pendingCast and
			curses.pendingCast.targetGuid == targetGuid and
			curses.pendingCast.spellName == lowercaseSpellNameNoRank then
		return true
	end

	return nil
end

function curses:ApplyCurse(spellId, lowercaseSpellName, targetGuid, startTime, duration, isCurrentPlayer)
	curses.pendingCast = {}

	if not curses.guids[targetGuid] then
		curses.guids[targetGuid] = {}
	end

	local texture = curses.trackedCurseNamesToTextures[lowercaseSpellName]
	if not texture then
		local _, _, tex = GetSpellInfo(spellId)
		texture = tex
	end

	curses.guids[targetGuid][lowercaseSpellName] = {
		duration = duration,
		start = startTime,
		spellID = spellId,
		targetGuid = targetGuid,
		currentPlayer = isCurrentPlayer,
		texture = texture
	}
end

function curses:RemoveCurse(guid, curseName)
	if curses.guids[guid] and curses.guids[guid][curseName] then
		curses.guids[guid][curseName] = nil
	end
	if curses.expiringSoundGuids[guid] and curses.expiringSoundGuids[guid][curseName] then
		curses.expiringSoundGuids[guid][curseName] = nil
	end
end

function curses:RemoveGuid(guid)
	curses.guids[guid] = nil
	curses.resistSoundGuids[guid] = nil
	curses.expiringSoundGuids[guid] = nil
	curses.requestedExpiringSoundGuids[guid] = nil
end

Cursive.curses = curses
