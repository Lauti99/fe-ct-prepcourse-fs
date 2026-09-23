Studio = {
    allowed = false,
    uiOpen = false,
    scenes = {},
}

function Studio.notify(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, true)
end

function Studio.canUse()
    if not Studio.allowed then
        Studio.notify('~r~No tienes permiso para usar el estudio.')
        return false
    end
    return true
end

function Studio.loadModel(hash)
    RequestModel(hash)
    local deadline = GetGameTimer() + 5000
    while not HasModelLoaded(hash) do
        if GetGameTimer() > deadline then
            Studio.notify('~r~No se pudo cargar el modelo.')
            return false
        end
        Wait(0)
    end
    return true
end

function Studio.loadAnimDict(dict)
    RequestAnimDict(dict)
    local deadline = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) do
        if GetGameTimer() > deadline then
            Studio.notify('~r~No se pudo cargar la animación.')
            return false
        end
        Wait(0)
    end
    return true
end

-- Permisos
RegisterNetEvent('studio:permission', function(allowed)
    Studio.allowed = allowed == true
end)

CreateThread(function()
    TriggerServerEvent('studio:requestPermission')
end)

-- Aparición del jugador (usa spawnmanager + basic-gamemode)
AddEventHandler('onClientGameTypeStart', function()
    exports.spawnmanager:setAutoSpawnCallback(function()
        local s = Config.Spawn
        exports.spawnmanager:spawnPlayer({
            x = s.x, y = s.y, z = s.z,
            heading = s.heading,
            model = s.model,
        }, function()
            SetPedDefaultComponentVariation(PlayerPedId())
        end)
    end)
    exports.spawnmanager:setAutoSpawn(true)
    exports.spawnmanager:forceRespawn()
end)
