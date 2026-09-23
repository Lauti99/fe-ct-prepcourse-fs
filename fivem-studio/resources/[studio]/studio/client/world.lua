-- Aplica el estado del mundo que sincroniza el servidor (GlobalState.studioWorld)
World = {}

local lastWeather

local function applyWeather(weather)
    if weather == lastWeather then return end
    lastWeather = weather
    ClearOverrideWeather()
    ClearWeatherTypePersist()
    SetWeatherTypeNowPersist(weather)
    SetWeatherTypeNow(weather)
    SetOverrideWeather(weather)
    local xmas = weather == 'XMAS'
    SetForceVehicleTrails(xmas)
    SetForcePedFootstepsTracks(xmas)
end

function World.apply(state)
    if type(state) ~= 'table' then return end
    applyWeather(state.weather)
    NetworkOverrideClockTime(state.hour, state.minute, 0)
    SetArtificialLightsState(state.blackout == true)
    SetArtificialLightsStateAffectsVehicles(false)
    SetWindSpeed(state.wind or 0.0)
end

function World.clearArea()
    local p = Freecam.active and Freecam.pos or GetEntityCoords(PlayerPedId())
    ClearArea(p.x, p.y, p.z, 100.0, true, false, false, false)
end

AddStateBagChangeHandler('studioWorld', 'global', function(_, _, value)
    World.apply(value)
    SetTimeout(50, Studio.pushState)
end)

-- Reaplica cada segundo (el juego intenta avanzar la hora por su cuenta)
CreateThread(function()
    while true do
        World.apply(GlobalState.studioWorld)
        Wait(1000)
    end
end)

-- Densidad de tráfico y peatones (0 = ciudad vacía)
CreateThread(function()
    while true do
        local state = GlobalState.studioWorld
        local d = state and state.density or 1.0
        if d < 1.0 then
            SetVehicleDensityMultiplierThisFrame(d)
            SetRandomVehicleDensityMultiplierThisFrame(d)
            SetParkedVehicleDensityMultiplierThisFrame(d)
            SetPedDensityMultiplierThisFrame(d)
            SetScenarioPedDensityMultiplierThisFrame(d, d)
            Wait(0)
        else
            Wait(500)
        end
    end
end)
