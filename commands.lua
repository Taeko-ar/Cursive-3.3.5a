-- Cursive commands setup for WotLK 3.3.5a

local L = AceLibrary("AceLocale-2.2"):new("Cursive")
local curseCommands = L["|cffffcc00Cursive:|cffffaaaa Commands:"]
local priorityChoices = L["|cffffcc00Priority choices:"]
local curseOptions = L["|cffffcc00Options (separate with ,):"]

local commandOptions = {
	warnings = L["Display text warnings when a curse fails to cast."],
	resistsound = L["Play a sound when a curse is resisted."],
	expiringsound = L["Play a sound when a curse is about to expire."],
	allowooc = L["Allow out of combat targets to be multicursed.  Would only consider using this solo to avoid potentially griefing raids/dungeons by pulling unintended mobs."],
	minhp = L["Minimum HP for a target to be considered.  Example usage minhp=10000. "],
	refreshtime = L["Time threshold at which to allow refreshing a curse.  Default is 0 seconds."],
	priotarget = L["Always prioritize current target when choosing target for multicurse.  Does not affect 'curse' command."],
	ignoretarget = L["Ignore the current target when choosing target for multicurse.  Does not affect 'curse' command."],
	playeronly = L["Only choose players and ignore npcs when choosing target for multicurse.  Does not affect 'curse' command."],
	istapped = L["Only choose mobs tagged by other players when choosing target for multicurse.  Does not affect 'curse' command."],
	name = L["Filter targets by name. Can be a partial match.  If no match is found, the command will do nothing."],
	ignorespellid = L["Ignore targets with the specified spell id already on them. Useful for ignoring targets that already have a shared debuff."],
	ignorespelltexture = L["Ignore targets with the specified spell texture already on them. Useful for ignoring targets that already have a shared debuff."],
	malediction = L["For Warlocks with the Malediction talent: when checking if Curse of Recklessness, Curse of the Elements, or Curse of Shadow is already on a target, check for Curse of Agony instead. Default is 1 (enabled). Set malediction=0 to disable and check for the original curse."],
}

local commands = {
	["curse"] = L["/cursive curse <spellName:str>|<guid?:str>|<options?:List<str>>: Casts spell if not already on target/guid"],
	["multicurse"] = L["/cursive multicurse <spellName:str>|<priority?:str>|<options?:List<str>>: Picks target based on priority and casts spell if not already on target"],
	["target"] = L["/cursive target <spellName:str>|<priority?:str>|<options?:List<str>>: Targets unit based on priority if spell in range and not already on target"],
}

local PRIORITY_HIGHEST_HP = "HIGHEST_HP"
local PRIORITY_LOWEST_HP = "LOWEST_HP"
local PRIORITY_RAID_MARK = "RAID_MARK"
local PRIORITY_RAID_MARK_SQUARE = "RAID_MARK_SQUARE"
local PRIORITY_INVERSE_RAID_MARK = "INVERSE_RAID_MARK"
local PRIORITY_HIGHEST_HP_RAID_MARK = "HIGHEST_HP_RAID_MARK"
local PRIORITY_HIGHEST_HP_RAID_MARK_SQUARE = "HIGHEST_HP_RAID_MARK_SQUARE"
local PRIORITY_HIGHEST_HP_INVERSE_RAID_MARK = "HIGHEST_HP_INVERSE_RAID_MARK"

local priorities = {
	[PRIORITY_HIGHEST_HP] = L["Target with the highest HP."],
	[PRIORITY_LOWEST_HP] = L["Target with the lowest HP."],
	[PRIORITY_RAID_MARK] = L["Target with the highest raid mark."],
	[PRIORITY_RAID_MARK_SQUARE] = L["Target with the highest raid mark with Cross set to -1 and Skull set to -2 (Square highest prio at 6)."],
	[PRIORITY_INVERSE_RAID_MARK] = L["Target with the lowest raid mark."],
	[PRIORITY_HIGHEST_HP_RAID_MARK] = L["Target with the highest HP and raid mark."],
	[PRIORITY_HIGHEST_HP_RAID_MARK_SQUARE] = L["Same as HIGHEST_HP_RAID_MARK but with RAID_MARK_SQUARE mark prio."],
	[PRIORITY_HIGHEST_HP_INVERSE_RAID_MARK] = L["Same as HIGHEST_HP_RAID_MARK but with INVERSE_RAID_MARK mark prio."]
}

local curseNoTarget = L["|cffffcc00Cursive:|cffffaaaa Couldn't find a target to curse."]

local function parseOptions(optionsStr)
	local options = {  }

	if optionsStr then
		for option, _ in pairs(commandOptions) do
			-- special case for minhp as it takes a param
			if option == "minhp" then
				local _, _, minHp = string.find(optionsStr, "minhp=(%d+)")
				if minHp then
					options["minhp"] = tonumber(minHp)
				end
			elseif option == "refreshtime" then
				local _, _, refreshTime = string.find(optionsStr, "refreshtime=(%d+)")
				if refreshTime then
					options["refreshtime"] = tonumber(refreshTime)
				end
			elseif option == "name" then
				local _, _, name = string.find(optionsStr, "name=([%w%s]+)")
				if name then
					options["name"] = name
				end
			elseif option == "ignorespellid" then
				local _, _, spellId = string.find(optionsStr, "ignorespellid=(%d+)")
				if spellId then
					options["ignorespellid"] = tonumber(spellId)
				end
			elseif option == "ignorespelltexture" then
				local _, _, texture = string.find(optionsStr, "ignorespelltexture=([%w_]+)")
				if texture then
					options["ignorespelltexture"] = texture
				end
			elseif option == "malediction" then
				local _, _, maledictionVal = string.find(optionsStr, "malediction=(%d)")
				if maledictionVal then
					options["malediction"] = tonumber(maledictionVal)
				end
			elseif string.find(optionsStr, option) then
				options[option] = true
			end
		end
	end

	return options
end

local function handleSlashCommands(msg, editbox)
	if not msg or msg == "" then
		if Cursive.optionsFrame then
			InterfaceOptionsFrame_OpenToCategory(Cursive.optionsFrame)
			InterfaceOptionsFrame_OpenToCategory(Cursive.optionsFrame)
		end
		return
	end
	-- get first word in string
	local _, _, command, args = string.find(msg, "(%w+) (.*)")
	if command == "curse" then
		local spellName, targetedGuid, optionsStr = Cursive.utils.strsplit("|", args)
		local options = parseOptions(optionsStr)
		Cursive:Curse(spellName, targetedGuid, options)
	elseif command == "multicurse" then
		local spellName, priority, optionsStr = Cursive.utils.strsplit("|", args)
		local options = parseOptions(optionsStr)
		Cursive:Multicurse(spellName, priority, options)
	elseif command == "target" then
		local spellName, priority, optionsStr = Cursive.utils.strsplit("|", args)
		local options = parseOptions(optionsStr)
		Cursive:Target(spellName, priority, options)
	else
		DEFAULT_CHAT_FRAME:AddMessage(L["|cffffcc00Cursive:|cffffaaaa Unknown command."])
		DEFAULT_CHAT_FRAME:AddMessage(curseCommands)
		for _, description in pairs(commands) do
			DEFAULT_CHAT_FRAME:AddMessage(description)
		end
	end
end

local crowdControlledSpellIds = {
	[700] = { name = L["sleep"], rank = 1, duration = 20 },
	[1090] = { name = L["sleep"], rank = 2, duration = 30 },
	[2937] = { name = L["sleep"], rank = 3, duration = 40 },

	[339] = { name = L["entangling roots"], rank = 1, duration = 12 },
	[1062] = { name = L["entangling roots"], rank = 2, duration = 15 },
	[5195] = { name = L["entangling roots"], rank = 3, duration = 18 },
	[5196] = { name = L["entangling roots"], rank = 4, duration = 21 },
	[9852] = { name = L["entangling roots"], rank = 5, duration = 24 },
	[9853] = { name = L["entangling roots"], rank = 6, duration = 27 },

	[2637] = { name = L["hibernate"], rank = 1, duration = 20 },
	[18657] = { name = L["hibernate"], rank = 2, duration = 30 },
	[18658] = { name = L["hibernate"], rank = 3, duration = 40 },

	[1425] = { name = L["shackle undead"], rank = 1, duration = 30 },
	[9486] = { name = L["shackle undead"], rank = 2, duration = 40 },
	[10956] = { name = L["shackle undead"], rank = 3, duration = 50 },

	-- polymorph
	[118] = { name = L["polymorph"], rank = L["Rank 1"], duration = 20 },
	[12824] = { name = L["polymorph"], rank = L["Rank 2"], duration = 30 },
	[12825] = { name = L["polymorph"], rank = L["Rank 3"], duration = 40 },
	[12826] = { name = L["polymorph"], rank = L["Rank 4"], duration = 50 },

	[28270] = { name = L["polymorph: cow"], rank = L["Rank 1"], duration = 50 },
	[28271] = { name = L["polymorph: turtle"], rank = L["Rank 1"], duration = 50 },
	[28272] = { name = L["polymorph: pig"], rank = L["Rank 1"], duration = 50 },

	[2878] = { name = L["turn undead"], rank = 1, duration = 10 },
	[5627] = { name = L["turn undead"], rank = 2, duration = 15 },
	[10326] = { name = L["turn undead"], rank = 3, duration = 20 },

	[2094] = { name = L["blind"], rank = 1, duration = 10 },
	[21060] = { name = L["blind"], rank = 1, duration = 10 },

	[6770] = { name = L["sap"], rank = 1, duration = 25 },
	[2070] = { name = L["sap"], rank = 2, duration = 35 },
	[11297] = { name = L["sap"], rank = 3, duration = 45 },

	[1776] = { name = L["gouge"], rank = 1, duration = 4 },
	[1777] = { name = L["gouge"], rank = 2, duration = 4 },
	[8629] = { name = L["gouge"], rank = 3, duration = 4 },
	[11285] = { name = L["gouge"], rank = 4, duration = 4 },
	[11286] = { name = L["gouge"], rank = 5, duration = 4 },

	[3355] = { name = L["freezing trap"], rank = 1, duration = 10 },
	[14308] = { name = L["freezing trap"], rank = 2, duration = 15 },
	[14309] = { name = L["freezing trap"], rank = 3, duration = 20 },

	[710] = { name = L["banish"], rank = 1, duration = 30 },
	[18647] = { name = L["banish"], rank = 2, duration = 30 },

	-- mind control effects
	[28410] = { name = "Chains of Kel'Thuzad" }, -- we aren't casting these, name doesn't matter
	[7621] = { name = "Arugal's Curse" },
	[24261] = { name = "Brain Wash" },
	[12888] = { name = "Cause Insanity" },
	[24327] = { name = "Cause Insanity" },
	[26079] = { name = "Cause Insanity" },
	[24327] = { name = "Cause Insanity" },
	[23174] = { name = "Chromatic Mutation" },
	[25806] = { name = "Creature of Nightmare" },
	[23298] = { name = "Demonic Doom" },
	[7645] = { name = "Dominate Mind" },
	[14515] = { name = "Dominate Mind" },
	[15859] = { name = "Dominate Mind" },
	[20604] = { name = "Dominate Mind" },
	[20740] = { name = "Dominate Mind" },
	[17405] = { name = "Domination" },
	[3442] = { name = "Enslave" },
	[13181] = { name = "Gnomish Mind Control Cap" },
	[26740] = { name = "Gnomish Mind Control Cap" },
	[12483] = { name = "Hex of Jammal'an" },
	[25772] = { name = "Mental Domination" },
	[7967] = { name = "Naralex's Nightmare" },
	[19469] = { name = "Poison Mind" },
	[17244] = { name = "Possess" },
	[22667] = { name = "Shadow Command" },
	[20668] = { name = "Sleepwalk" },
	[785] = { name = "True Fulfillment" },
	[26195] = { name = "Whisperings of C'Thun" },
	[26197] = { name = "Whisperings of C'Thun" },
	[26198] = { name = "Whisperings of C'Thun" },
	[26258] = { name = "Whisperings of C'Thun" },
	[26259] = { name = "Whisperings of C'Thun" },
	[24178] = { name = "Will of Hakkar" },

	-- immunity effects
	[642] = { name = "Divine Shield" },
	[1020] = { name = "Divine Shield" },
	[13874] = { name = "Divine Shield" },
	[5573] = { name = "Divine Protection" },
	[13007] = { name = "Divine Protection" },
	[6356] = { name = "Spell Immunity" },
	[6724] = { name = "Light of Elune" },
	[7121] = { name = "Anti-Magic Shield" },
	[19645] = { name = "Anti-Magic Shield" },
	[24021] = { name = "Anti-Magic Shield" },
	[8361] = { name = "Purity" },
	[8611] = { name = "Phase Shift" },
	[45713] = { name = "Phase Shift" },
	[9438] = { name = "Arcane Bubble" },
	[11958] = { name = "Ice Block" },
	[12843] = { name = "Mordresh's Shield" },
	[21892] = { name = "Arcane Protection" },
	[51096] = { name = "Worgen Dimension" },
	[51228] = { name = "Invulnerability" },
	[52010] = { name = "Pending Detonation" },
	[53225] = { name = "Ward of Vorgendor" },
	[57644] = { name = "Veil of Vorgendor" },
}

local spellImmuneGuids = {
  ["0xF1300030A9014A44"] = true, -- Blackwing Spellbinder
  ["0xF1300030A911F78C"] = true, -- Blackwing Spellbinder
  ["0xF1300030A911F78D"] = true, -- Blackwing Spellbinder
  ["0xF1300030A9014EFE"] = true, -- Blackwing Spellbinder
  ["0xF1300030A9014F08"] = true, -- Blackwing Spellbinder
  ["0xF1300030A9014E75"] = true, -- Blackwing Spellbinder
  ["0xF1300030A9014E6D"] = true, -- Blackwing Spellbinder
}

local function isMobCrowdControlled(guid)
	local token = Cursive.core:GetTokenForGUID(guid)
	if token then
		for i = 1, 40 do
			local name, _, _, _, _, _, _, _, _, _, spellId = UnitDebuff(token, i)
			if not name then break end
			if crowdControlledSpellIds[spellId] then
				return true
			end
		end
	end
	return false
end

local function isMobSpellImmune(guid)
	return spellImmuneGuids[guid] and true or false
end

local function GetSquarePrioRaidTargetIndex(guid)
	local token = Cursive.core:GetTokenForGUID(guid)
	local index = token and GetRaidTargetIndex(token) or 0
	if index == 7 then
		return 0 -- cross becomes 0
	elseif index == 8 then
		return -1 -- skull becomes -1
	elseif index == 0 then
		return -2 -- nomark becomes -2
	end
	return index or -2
end

local function hasSpellId(guid, ignoreSpellId)
	local token = Cursive.core:GetTokenForGUID(guid)
	if token then
		for i = 1, 40 do
			local name, _, _, _, _, _, _, _, _, _, spellId = UnitDebuff(token, i)
			if not name then break end
			if spellId == ignoreSpellId then
				return true
			end
		end
	end
	return false
end

local function hasSpellTexture(guid, ignoreTexture)
	local token = Cursive.core:GetTokenForGUID(guid)
	if token then
		for i = 1, 40 do
			local name, _, texture = UnitDebuff(token, i)
			if not name then break end
			if texture and string.find(string.lower(texture), string.lower(ignoreTexture)) then
				return true
			end
		end
		for i = 1, 40 do
			local name, _, texture = UnitBuff(token, i)
			if not name then break end
			if texture and string.find(string.lower(texture), string.lower(ignoreTexture)) then
				return true
			end
		end
	end
	return false
end

local function passedOptionFilters(guid, options)
	local token = Cursive.core:GetTokenForGUID(guid)
	if options["name"] then
		local name = token and UnitName(token) or (Cursive.core.cache[guid] and Cursive.core.cache[guid].name)
		if not name or not string.find(name, options["name"]) then
			return false
		end
	end
	if options["ignorespellid"] then
		if hasSpellId(guid, options["ignorespellid"]) then
			return false
		end
	end
	if options["ignorespelltexture"] then
		if hasSpellTexture(guid, options["ignorespelltexture"]) then
			return false
		end
	end
	if options["playeronly"] then
		local isPlayer = token and UnitIsPlayer(token) or (Cursive.core.cache[guid] and Cursive.core.cache[guid].isPlayer)
		if not isPlayer then return false end
	end
	if options["istapped"] then
		local isTapped = token and UnitIsTapped(token) or (Cursive.core.cache[guid] and Cursive.core.cache[guid].isTapped)
		if not isTapped then return false end
	end
	return true
end

local function pickTarget(selectedPriority, lowercaseSpellNameNoRank, checkRange, options)
	local highestPrimaryValue = -10
	local highestSecondaryValue = -10
	local targetedGuid = nil

	if selectedPriority == PRIORITY_LOWEST_HP then
		highestPrimaryValue = 999999999999
	end

	local minHp = options["minhp"]
	local ignoreInFight = options["allowooc"]
	local refreshTime = options["refreshtime"]

	local currentTargetGuid = UnitGUID("target")
	local seenRaidMark = nil

	for guid, time in pairs(Cursive.core.guids) do
		local shouldDisplay = Cursive:ShouldDisplayGuid(guid)
		if shouldDisplay then
			if not options["ignoretarget"] or guid ~= currentTargetGuid then
				if ignoreInFight or Cursive.filter.infight(guid) or guid == currentTargetGuid then
					if passedOptionFilters(guid, options) then
						local passedRangeCheck = false
						local token = Cursive.core:GetTokenForGUID(guid)
						if token then
							if IsSpellInRange then
								local result = IsSpellInRange(lowercaseSpellNameNoRank, token)
								if result == -1 then
									passedRangeCheck = checkRange == false or CheckInteractDistance(token, 4)
								else
									passedRangeCheck = result == 1
								end
							else
								passedRangeCheck = checkRange == false or CheckInteractDistance(token, 4)
							end
						else
							passedRangeCheck = (checkRange == false)
						end

						if passedRangeCheck then
							if not Cursive.curses:HasCurse(lowercaseSpellNameNoRank, guid, refreshTime, options["malediction"]) and
									not isMobCrowdControlled(guid) and
									not isMobSpellImmune(guid) then
								
								local token = Cursive.core:GetTokenForGUID(guid)
								local mobHp = token and UnitHealth(token) or (Cursive.core.cache[guid] and Cursive.core.cache[guid].maxHp or 0)
								
								if not minHp or mobHp >= minHp then
									local primaryValue = -1
									local secondaryValue = -1
									if options["priotarget"] and guid == currentTargetGuid then
										seenRaidMark = true
										primaryValue = 999999999999
									elseif selectedPriority == PRIORITY_HIGHEST_HP then
										local t = Cursive.core:GetTokenForGUID(guid)
										primaryValue = t and UnitHealth(t) or (Cursive.core.cache[guid] and Cursive.core.cache[guid].maxHp or 0)
									elseif selectedPriority == PRIORITY_LOWEST_HP then
										local t = Cursive.core:GetTokenForGUID(guid)
										primaryValue = t and UnitHealth(t) or (Cursive.core.cache[guid] and Cursive.core.cache[guid].maxHp or 999999999999)
									elseif selectedPriority == PRIORITY_RAID_MARK then
										local t = Cursive.core:GetTokenForGUID(guid)
										primaryValue = t and GetRaidTargetIndex(t) or 0
									elseif selectedPriority == PRIORITY_RAID_MARK_SQUARE then
										primaryValue = GetSquarePrioRaidTargetIndex(guid)
									elseif selectedPriority == PRIORITY_INVERSE_RAID_MARK then
										local t = Cursive.core:GetTokenForGUID(guid)
										primaryValue = -1 * (t and GetRaidTargetIndex(t) or 9)
									elseif selectedPriority == PRIORITY_HIGHEST_HP_RAID_MARK then
										local t = Cursive.core:GetTokenForGUID(guid)
										secondaryValue = t and GetRaidTargetIndex(t) or 0
										if secondaryValue > 0 and not seenRaidMark then
											highestPrimaryValue = -10
											seenRaidMark = true
										end
										primaryValue = t and UnitHealth(t) or (Cursive.core.cache[guid] and Cursive.core.cache[guid].maxHp or 0)
									elseif selectedPriority == PRIORITY_HIGHEST_HP_RAID_MARK_SQUARE then
										secondaryValue = GetSquarePrioRaidTargetIndex(guid)
										if secondaryValue > -2 and not seenRaidMark then
											highestPrimaryValue = -10
											seenRaidMark = true
										end
										local t = Cursive.core:GetTokenForGUID(guid)
										primaryValue = t and UnitHealth(t) or (Cursive.core.cache[guid] and Cursive.core.cache[guid].maxHp or 0)
									elseif selectedPriority == PRIORITY_HIGHEST_HP_INVERSE_RAID_MARK then
										local t = Cursive.core:GetTokenForGUID(guid)
										secondaryValue = -1 * (t and GetRaidTargetIndex(t) or 9)
										if secondaryValue > -9 and not seenRaidMark then
											highestPrimaryValue = -10
											seenRaidMark = true
										end
										primaryValue = t and UnitHealth(t) or (Cursive.core.cache[guid] and Cursive.core.cache[guid].maxHp or 0)
									end

									if selectedPriority == PRIORITY_LOWEST_HP then
										if primaryValue < highestPrimaryValue then
											highestPrimaryValue = primaryValue
											targetedGuid = guid
										end
									elseif primaryValue > highestPrimaryValue then
										highestPrimaryValue = primaryValue
										highestSecondaryValue = secondaryValue
										targetedGuid = guid
									elseif primaryValue == highestPrimaryValue and secondaryValue > highestSecondaryValue then
										highestSecondaryValue = secondaryValue
										targetedGuid = guid
									end
								end
							end
						end
					end
				end
			end
		end
	end

	return targetedGuid
end

local function castSpellWithOptions(spellName, lowercaseSpellNameNoRank, targetedGuid, options)
	-- Protected action, warning printed in callers
end

function Cursive:Curse(spellName, targetedGuid, options)
	DEFAULT_CHAT_FRAME:AddMessage(L["|cffffcc00Cursive:|cffffaaaa Spell casting via slash commands is disabled in WotLK. Please use mouseover macros."])
	return false
end

local function getSpellTarget(spellName, priority, options)
	if not spellName then
		DEFAULT_CHAT_FRAME:AddMessage(commands["multicurse"])
		return
	end

	if priority and not priorities[priority] then
		DEFAULT_CHAT_FRAME:AddMessage(priorityChoices)
		for choice, description in pairs(priorities) do
			DEFAULT_CHAT_FRAME:AddMessage("|CFFFFFF00" .. choice .. "|R: " .. description)
		end
		return
	end

	local selectedPriority = priority or PRIORITY_HIGHEST_HP
	local lowercaseSpellNameNoRank = Cursive.utils.GetLowercaseSpellNameNoRank(spellName)

	return pickTarget(selectedPriority, lowercaseSpellNameNoRank, true, options)
end

function Cursive:Multicurse(spellName, priority, options)
	DEFAULT_CHAT_FRAME:AddMessage(L["|cffffcc00Cursive:|cffffaaaa Spell casting via slash commands is disabled in WotLK. Please use mouseover macros."])
	return false
end

function Cursive:GetTarget(spellName, priority, options)
	return getSpellTarget(spellName, priority, options)
end

function Cursive:Target(spellName, priority, options)
	if InCombatLockdown() then
		DEFAULT_CHAT_FRAME:AddMessage(L["|cffffcc00Cursive:|cffffaaaa Targeting via slash commands is disabled in combat."])
		return false
	end

	local targetedGuid = getSpellTarget(spellName, priority, options)
	if targetedGuid then
		local token = Cursive.core:GetTokenForGUID(targetedGuid)
		if token then
			TargetUnit(token)
			return true
		else
			local cached = Cursive.core.cache[targetedGuid]
			if cached and cached.name then
				Cursive.utils.TargetByName(cached.name)
				return true
			end
		end
	end
	return false
end

SLASH_CURSIVE1 = "/cursive" --creating the slash command
SlashCmdList["CURSIVE"] = handleSlashCommands --associating the function with the slash command
