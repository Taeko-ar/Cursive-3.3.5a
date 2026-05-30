local L = AceLibrary("AceLocale-2.2"):new("Cursive")
Cursive = LibStub("AceAddon-3.0"):NewAddon("Cursive", "AceEvent-3.0", "AceConsole-3.0", "AceTimer-3.0")

Cursive.nampower = true -- Keep as compatibility fallback for top-of-file checks

function Cursive:OnInitialize()
    -- Called when the addon is loaded. Database is registered in settings.lua
end

function Cursive:OnEnable()
	DEFAULT_CHAT_FRAME:AddMessage(L["|cffffcc00Cursive:|cffffaaaa Loaded.  /cursive for commands and minimap icon for options."])

	Cursive.curses:LoadCurses()
	if Cursive.db and Cursive.db.profile.enabled then
		Cursive.core.enable()
	end
end

