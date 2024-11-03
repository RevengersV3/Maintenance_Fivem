-- Constants for color codes to improve readability
local COLORS = {
    DEBUG = "^3",
    INFO = "^4",
    RESET = "^0"
}

-- Cached configuration checks to avoid repeated table lookups
local isDebugEnabled = Config.Debug
local isStatusEnabled = Config.Status
local currentLocale = Config.Locale
local allowedIds = Config.AllowedIDs or {}
local lang = Language.Country[currentLocale] or {}

-- Optimized Debug function using string formatting
local function Debug(...)
    if not isDebugEnabled then return end
    
    local args = {...}
    local message = table.concat(args, " ")
    print(string.format("%s[DEBUG] %s%s", COLORS.DEBUG, message, COLORS.RESET))
end

-- Optimized GetIdentifier function using pattern matching
local function GetIdentifier(player)
    local identifiers = GetPlayerIdentifiers(player)
    for i = 1, #identifiers do
        local id = identifiers[i]
        if id:match("^license:") then
            return id
        end
    end
    return ""
end

-- Optimized resource start handler
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    local messages = {
        "                                                             ",
        string.format("The resource %s%s%s has been %sstarted%s", 
            COLORS.INFO, resourceName, COLORS.RESET, COLORS.INFO, COLORS.RESET),
        "                                                             ",
        string.format("               Created by %sKamion#1323%s", 
            COLORS.INFO, COLORS.RESET),
        "                                                             "
    }
    
    for _, message in ipairs(messages) do
        Debug(message)
    end
end)

-- Improved player connection handler with better error handling and performance
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    if not isStatusEnabled then return end
    
    local _src = source
    local playerId = GetIdentifier(_src)
    
    -- Early return if no valid identifier
    if playerId == "" then
        Debug("No valid identifier found for player " .. name)
        return
    end
    
    local function DeferralUpdate(message, waitTime)
        deferrals.update(message)
        Debug("Debug: " .. message .. " for player " .. name)
        if waitTime then
            Citizen.Wait(waitTime)
        end
    end
    
    -- Start connection process
    deferrals.defer()
    
    -- Connection status updates with error handling
    local function ProcessConnection()
        -- Initial status check
        DeferralUpdate(lang['Status'], 2000)
        
        -- Verification process
        DeferralUpdate(lang['Verif'], 2500)
        
        -- Check if player is allowed
        local isAllowed = false
        for _, allowedId in ipairs(allowedIds) do
            if playerId == allowedId then
                isAllowed = true
                break
            end
        end
        
        -- Final status update
        if isAllowed then
            DeferralUpdate(lang['BypassOn'], 2500)
            deferrals.done()
        else
            DeferralUpdate(lang['BypassOff'])
        end
    end
    
    -- Execute connection process with error handling
    local success, error = pcall(ProcessConnection)
    if not success then
        Debug("Error during connection process: " .. tostring(error))
        deferrals.done("Une erreur s'est produite lors de la connexion.")
    end
end)

-- Cache cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Clear cached variables
    isDebugEnabled = nil
    isStatusEnabled = nil
    currentLocale = nil
    allowedIds = nil
    lang = nil
    
    Debug("Resource stopped, cache cleared")
end)