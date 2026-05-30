local filter = {}

filter.attackable = function(guid)
	local token = Cursive.core:GetTokenForGUID(guid)
	if token then
		return UnitCanAttack("player", token) and true or false
	else
		local cached = Cursive.core.cache[guid]
		return (cached and cached.canAttack) and true or false
	end
end

filter.player = function(guid)
	local token = Cursive.core:GetTokenForGUID(guid)
	if token then
		return UnitIsPlayer(token) and true or false
	else
		local cached = Cursive.core.cache[guid]
		return (cached and cached.isPlayer) and true or false
	end
end

filter.notplayer = function(guid)
	return not filter.player(guid)
end

filter.infight = function(guid)
	local token = Cursive.core:GetTokenForGUID(guid)
	if token then
		return UnitAffectingCombat(token) and true or false
	else
		return UnitAffectingCombat("player") and true or false
	end
end

filter.hascurse = function(guid)
	return Cursive.curses:HasAnyCurse(guid) and true or false
end

filter.alive = function(guid)
	local token = Cursive.core:GetTokenForGUID(guid)
	if token then
		return not UnitIsDead(token) and true or false
	else
		return true -- Dead units are cleared by UNIT_DIED combat log events
	end
end

filter.range = function(guid)
	local token = Cursive.core:GetTokenForGUID(guid)
	if token then
		local spell = nil
		if Cursive.curses.isWarlock then spell = GetSpellInfo(172) -- Corruption
		elseif Cursive.curses.isPriest then spell = GetSpellInfo(589) -- SW:P
		elseif Cursive.curses.isMage then spell = GetSpellInfo(118) -- Polymorph
		elseif Cursive.curses.isDruid then spell = GetSpellInfo(770) -- FF
		end
		
		if spell and IsSpellInRange then
			return IsSpellInRange(spell, token) == 1
		end
		return CheckInteractDistance(token, 4) and true or false
	end
	return false
end

filter.icon = function(guid)
	local token = Cursive.core:GetTokenForGUID(guid)
	if token then
		return GetRaidTargetIndex(token) and true or false
	end
	
	-- Scan all possible tokens to see if any has a raid target index matching this GUID
	for i = 1, 8 do
		local markToken = Cursive.core:GetTokenForGUID(guid)
		if markToken and GetRaidTargetIndex(markToken) then
			return true
		end
	end
	return false
end

filter.normal = function(guid)
	local token = Cursive.core:GetTokenForGUID(guid)
	local classification
	if token then
		classification = UnitClassification(token)
	else
		local cached = Cursive.core.cache[guid]
		classification = cached and cached.classification
	end
	return classification == "normal" and true or false
end

filter.elite = function(guid)
	local token = Cursive.core:GetTokenForGUID(guid)
	local classification
	if token then
		classification = UnitClassification(token)
	else
		local cached = Cursive.core.cache[guid]
		classification = cached and cached.classification
	end
	return (classification == "elite" or classification == "rareelite") and true or false
end

filter.hostile = function(guid)
	local token = Cursive.core:GetTokenForGUID(guid)
	if token then
		return UnitIsEnemy("player", token) and true or false
	else
		local cached = Cursive.core.cache[guid]
		return (cached and cached.isEnemy) and true or false
	end
end

filter.notignored = function(guid)
	if not Cursive.db.profile.ignorelist or #Cursive.db.profile.ignorelist == 0 then
		return true
	end

	local unitName = nil
	local token = Cursive.core:GetTokenForGUID(guid)
	if token then
		unitName = UnitName(token)
	else
		local cached = Cursive.core.cache[guid]
		unitName = cached and cached.name
	end

	if not unitName then
		return true
	end
	
	for _, str in ipairs(Cursive.db.profile.ignorelist) do
		if string.find(string.lower(unitName), string.lower(str), nil, not Cursive.db.profile.ignorelistuseregex) then
			return false
		end
	end
	return true
end

Cursive.filter = filter

function Cursive:ShouldDisplayGuid(guid)
	-- Dead units cleanup
	if not Cursive.filter.alive(guid) then
		return false
	end

	local targetToken = Cursive.core:GetTokenForGUID(guid)
	local currentTargetGuid = UnitGUID("target")

	-- always show target if attackable
	if (currentTargetGuid == guid) and filter.attackable(guid) then
		return true
	end

	-- always show raid marks if attackable and not in combat or this guid is affecting combat
	if filter.icon(guid) and filter.attackable(guid) and (not UnitAffectingCombat("player") or UnitAffectingCombat(targetToken or "target")) then
		return true
	end

	if Cursive.db.profile.filterincombat and not filter.infight(guid) then
		return false
	end

	if Cursive.db.profile.filterhascurse and not filter.hascurse(guid) then
		return false
	end

	if Cursive.db.profile.filterhostile and not filter.hostile(guid) then
		return false
	end

	if Cursive.db.profile.filterattackable and not filter.attackable(guid) then
		return false
	end

	if Cursive.db.profile.filterrange and not filter.range(guid) then
		return false
	end

	if Cursive.db.profile.filterraidmark and not filter.icon(guid) then
		return false
	end

	if Cursive.db.profile.filterplayer and not filter.player(guid) then
		return false
	end

	if Cursive.db.profile.filternotplayer and not filter.notplayer(guid) then
		return false
	end

	if Cursive.db.profile.filterignored and not filter.notignored(guid) then
		return false
	end

	return true
end
