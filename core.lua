Cursive.core = CreateFrame("Frame", "CursiveCore", UIParent)

Cursive.core.guids = {}
Cursive.core.cache = {} -- Cache for unit details (Name, Class, maxHP, reaction) when token is available

local scanTokens = {
	"target",
	"focus",
	"mouseover",
	"pet",
	"targettarget",
	"focustarget"
}
for i = 1, 4 do
	table.insert(scanTokens, "party" .. i)
	table.insert(scanTokens, "party" .. i .. "target")
	table.insert(scanTokens, "party" .. i .. "targettarget")
	table.insert(scanTokens, "partypet" .. i .. "target")
end
for i = 1, 40 do
	table.insert(scanTokens, "raid" .. i)
	table.insert(scanTokens, "raid" .. i .. "target")
	table.insert(scanTokens, "raid" .. i .. "targettarget")
end
for i = 1, 4 do
	table.insert(scanTokens, "boss" .. i)
	table.insert(scanTokens, "boss" .. i .. "target")
end
for i = 1, 5 do
	table.insert(scanTokens, "arena" .. i)
	table.insert(scanTokens, "arena" .. i .. "target")
end
table.insert(scanTokens, "pettarget")

function Cursive.core:GetTokenForGUID(guid)
	if not guid then return nil end
	for _, token in ipairs(scanTokens) do
		if UnitExists(token) and UnitGUID(token) == guid then
			return token
		end
	end
	return nil
end

function Cursive.core:CacheUnitInfo(guid, token)
	if not guid or not token or not UnitExists(token) then return end
	
	local name = UnitName(token)
	local maxHp = UnitHealthMax(token)
	local isPlayer = UnitIsPlayer(token)
	local canAttack = UnitCanAttack("player", token)
	local isEnemy = UnitIsEnemy("player", token)
	local classification = UnitClassification(token)
	local level = UnitLevel(token)
	local isTapped = UnitIsTapped(token)
	
	local class = nil
	if isPlayer then
		_, class = UnitClass(token)
	end
	
	Cursive.core.cache[guid] = {
		name = name,
		maxHp = maxHp,
		isPlayer = isPlayer,
		class = class,
		canAttack = canAttack,
		isEnemy = isEnemy,
		classification = classification,
		level = level,
		isTapped = isTapped,
		lastSeen = GetTime()
	}
end

Cursive.core.add = function(unit)
	if UnitExists(unit) and not UnitIsDead(unit) then
		local guid = UnitGUID(unit)
		if guid then
			Cursive.core.guids[guid] = GetTime()
			Cursive.core:CacheUnitInfo(guid, unit)
		end
	end
end

Cursive.core.addGuid = function(guid, name, flags)
	if guid then
		Cursive.core.guids[guid] = GetTime()
		if name and not Cursive.core.cache[guid] then
			local isEnemy = true
			local isPlayer = false
			if flags then
				isPlayer = (bit.band(flags, 0x00000400) > 0)
				if isPlayer then
					isEnemy = (bit.band(flags, 0x00000060) > 0)
				else
					isEnemy = (bit.band(flags, 0x00000010) == 0) -- Not friendly = enemy/neutral
				end
			end
			Cursive.core.cache[guid] = {
				name = name,
				canAttack = isEnemy,
				isEnemy = isEnemy,
				isPlayer = isPlayer,
				lastSeen = GetTime()
			}
			DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Cursive:|r Registered enemy: " .. tostring(name) .. " (isEnemy=" .. tostring(isEnemy) .. ")")
		elseif Cursive.core.cache[guid] then
			Cursive.core.cache[guid].lastSeen = GetTime()
		end
		
		-- Try to resolve immediately if there's a token
		local token = Cursive.core:GetTokenForGUID(guid)
		if token then
			Cursive.core:CacheUnitInfo(guid, token)
		end
	end
end

Cursive.core.remove = function(guid)
	Cursive.core.guids[guid] = nil
	Cursive.core.cache[guid] = nil
end

Cursive.core.enable = function()
	Cursive.core:RegisterEvent("PLAYER_TARGET_CHANGED")
	Cursive.core:RegisterEvent("PLAYER_FOCUS_CHANGED")
	Cursive.core:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	Cursive.core:RegisterEvent("UNIT_TARGET")
	Cursive.core:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

Cursive.core.disable = function()
	Cursive.core:UnregisterAllEvents()
	Cursive.core.guids = {}
	Cursive.core.cache = {}
end

Cursive.core:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_TARGET_CHANGED" then
		self.add("target")
	elseif event == "PLAYER_FOCUS_CHANGED" then
		self.add("focus")
	elseif event == "UPDATE_MOUSEOVER_UNIT" then
		self.add("mouseover")
	elseif event == "UNIT_TARGET" then
		local unit = ...
		if unit then
			self.add(unit .. "target")
		end
	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
		local _, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags = ...
		if eventType ~= "UNIT_DIED" and eventType ~= "UNIT_DESTROYED" then
			if sourceGUID and string.sub(string.upper(sourceGUID), 1, 3) == "0xF" then
				self.addGuid(sourceGUID, sourceName, sourceFlags)
			end
			if destGUID and string.sub(string.upper(destGUID), 1, 3) == "0xF" then
				self.addGuid(destGUID, destName, destFlags)
			end
		end
	end
end)
