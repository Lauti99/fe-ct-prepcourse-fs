Studio = {}

function Studio.isAllowed(src)
    return IsPlayerAceAllowed(src, Config.Permission)
end

RegisterNetEvent('studio:requestPermission', function()
    local src = source
    TriggerClientEvent('studio:permission', src, Studio.isAllowed(src))
end)
