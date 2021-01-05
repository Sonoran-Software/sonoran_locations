--[[
    Sonaran CAD Plugins

    Plugin Name: locations
    Creator: SonoranCAD
    Description: Implements location updating for players
]]
local pluginConfig = Config.GetPluginConfig("locations")

if pluginConfig.enabled then
    local currentLocation = nil
    local lastSentTime = nil

    local function sendLocation()
        local pos = GetEntityCoords(PlayerPedId())
        local var1, var2 = GetStreetNameAtCoord(pos.x, pos.y, pos.z, Citizen.ResultAsInteger(), Citizen.ResultAsInteger())
        local postal = nil
        if isPluginLoaded("postals") then
            postal = getNearestPostal()
        else
            pluginConfig.prefixPostal = false
        end
        -- Determine location format
        if (GetStreetNameFromHashKey(var2) == '') then
            currentLocation = GetStreetNameFromHashKey(var1)
            if (currentLocation ~= lastLocation) then
                -- Updated location - Save and send to server API call queue
                lastLocation = currentLocation
            end
        else 
            currentLocation = GetStreetNameFromHashKey(var1) .. ' / ' .. GetStreetNameFromHashKey(var2)
            if (currentLocation ~= lastLocation) then
                -- Updated location - Save and send to server API call queue
                lastLocation = currentLocation
            end
        end
        if pluginConfig.prefixPostal and postal ~= nil then
            currentLocation = "["..tostring(postal).."] "..currentLocation
        elseif postal == nil and pluginConfig.prefixPostal == true then
            debugLog("Unable to send postal because I got a null response from getNearestPostal()?!")
        end
        TriggerServerEvent('SonoranCAD::locations:SendLocation', currentLocation) 
        lastSentTime = GetGameTimer()
    end

    Citizen.CreateThread(function()
        while true do
            while not NetworkIsPlayerActive(PlayerId()) do
                Wait(10)
            end
            sendLocation()
            -- Wait (1000ms) before checking for an updated unit location
            Citizen.Wait(pluginConfig.checkTime)
        end
    end)

    Citizen.CreateThread(function()
        while true do
            while not NetworkIsPlayerActive(PlayerId()) do
                Wait(10)
            end
            Wait(10000)
            if lastSentTime == nil then
                TriggerServerEvent("SonoranCAD::locations:ErrorDetection", true)
                warnLog("Warning: No location data has been sent yet. Check for errors.")
            else
                if (GetGameTimer() - lastSentTime) > 10000 then
                    TriggerServerEvent("SonoranCAD::locations:ErrorDetection", false)
                    warnLog("Warning: Locations have not been sent recently.")
                end
            end
            Wait(30000)
        end
    end)

end