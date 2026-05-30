-- Cursive AceLocale-2.2 to AceLocale-3.0 Compatibility Wrapper
local AceLocale3 = LibStub("AceLocale-3.0")
local L_enUS = AceLocale3:NewLocale("Cursive", "enUS", true)
local L_zhCN = AceLocale3:NewLocale("Cursive", "zhCN")

local L_compat = setmetatable({}, {
    __index = function(t, k)
        local activeL = AceLocale3:GetLocale("Cursive", true)
        if activeL then
            return activeL[k]
        end
        return k
    end,
    __newindex = function(t, k, v)
        local activeL = AceLocale3:GetLocale("Cursive", true)
        if activeL then
            activeL[k] = v
        end
    end
})

function L_compat:RegisterTranslations(lang, func)
    local targetL = (lang == "enUS") and L_enUS or L_zhCN
    if targetL then
        local translations = func()
        for k, v in pairs(translations) do
            if v == true then
                targetL[k] = k
            else
                targetL[k] = v
            end
        end
    end
end

local localeCompat = {}
function localeCompat:new(name)
    return L_compat
end

-- Compatibility version and interface for standard AceLibrary registration
function localeCompat:GetLibraryVersion()
    return "AceLocale-2.2", 2200
end

if not AceLibrary then
    AceLibrary = setmetatable({}, {
        __call = function(self, lib)
            if lib == "AceLocale-2.2" then
                return localeCompat
            end
        end,
        __index = function(self, key)
            if key == "HasInstance" then
                return function(self, major, minor)
                    return false
                end
            end
        end
    })
else
    if type(AceLibrary) == "table" and AceLibrary.Register then
        -- Register with a high minor version so we override any older version safely
        AceLibrary:Register(localeCompat, "AceLocale-2.2", 2200)
    end
end
