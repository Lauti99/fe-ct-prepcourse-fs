-- Estado del mundo compartido por todos los jugadores
local state = {
    weather = Config.World.weather,
    hour = Config.World.hour,
    minute = Config.World.minute,
    freezeTime = Config.World.freezeTime,
    blackout = false,
    density = 1.0,
    wind = 0.0,
}

local function publish()
    local copy = {}
    for k, v in pairs(state) do copy[k] = v end
    GlobalState.studioWorld = copy
end

publish()

RegisterNetEvent('studio:setWorld', function(patch)
    local src = source
    if not Studio.isAllowed(src) or type(patch) ~= 'table' then return end

    if patch.weather ~= nil and Utils.findById(Config.Weathers, patch.weather) then
        state.weather = patch.weather
    end
    if patch.hour ~= nil then state.hour = math.floor(Utils.clamp(Utils.num(patch.hour, state.hour), 0, 23)) end
    if patch.minute ~= nil then state.minute = math.floor(Utils.clamp(Utils.num(patch.minute, state.minute), 0, 59)) end
    if patch.freezeTime ~= nil then state.freezeTime = patch.freezeTime == true end
    if patch.blackout ~= nil then state.blackout = patch.blackout == true end
    if patch.density ~= nil then state.density = Utils.clamp(Utils.num(patch.density, 1.0), 0.0, 1.0) end
    if patch.wind ~= nil then state.wind = Utils.clamp(Utils.num(patch.wind, 0.0), 0.0, 12.0) end

    publish()
end)

-- Reloj del servidor cuando el tiempo no está congelado
CreateThread(function()
    while true do
        Wait(Config.World.msPerGameMinute)
        if not state.freezeTime then
            state.minute = state.minute + 1
            if state.minute >= 60 then
                state.minute = 0
                state.hour = (state.hour + 1) % 24
            end
            publish()
        end
    end
end)
