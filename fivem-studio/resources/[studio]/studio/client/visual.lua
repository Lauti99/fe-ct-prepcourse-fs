-- Modo foto / ajustes visuales locales (solo los ve este jugador)
Visual = {
    hideHud = false,
    letterbox = false,
    grid = false,
    hidePlayer = false,
    filter = '',
    filterStrength = 1.0,
    timeScale = 1.0,
}

-- Barras 2.39:1 sobre pantalla 16:9
local BAR = (1.0 - (16.0 / 2.39) / 9.0) / 2.0

local function applyFilter()
    if Visual.filter == '' then
        ClearTimecycleModifier()
    else
        SetTimecycleModifier(Visual.filter)
        SetTimecycleModifierStrength(Visual.filterStrength)
    end
end

function Visual.set(data)
    for _, key in ipairs({ 'hideHud', 'letterbox', 'grid', 'hidePlayer' }) do
        if data[key] ~= nil then Visual[key] = data[key] == true end
    end
    if data.filter ~= nil and Utils.findById(Config.Filters, data.filter) then
        Visual.filter = data.filter
    end
    if data.filterStrength ~= nil then
        Visual.filterStrength = Utils.clamp(Utils.num(data.filterStrength, 1.0), 0.0, 1.0)
    end
    if data.timeScale ~= nil then
        Visual.timeScale = Utils.clamp(Utils.num(data.timeScale, 1.0), 0.05, 1.0)
        if Visual.timeScale == 1.0 then SetTimeScale(1.0) end
    end

    applyFilter()
    SetEntityVisible(PlayerPedId(), not Visual.hidePlayer, false)
end

function Visual.reset()
    Visual.set({ hideHud = false, letterbox = false, grid = false, hidePlayer = false, filter = '', timeScale = 1.0 })
end

local function drawGrid()
    local a = 90
    for _, x in ipairs({ 1 / 3, 2 / 3 }) do DrawRect(x, 0.5, 0.0008, 1.0, 255, 255, 255, a) end
    for _, y in ipairs({ 1 / 3, 2 / 3 }) do DrawRect(0.5, y, 1.0, 0.0012, 255, 255, 255, a) end
end

CreateThread(function()
    while true do
        local playing = Cinematic and Cinematic.playing
        local letterbox = Visual.letterbox or (playing and Cinematic.settings.letterbox)
        local busy = Visual.hideHud or letterbox or Visual.grid or playing or Visual.timeScale ~= 1.0

        if busy then
            if Visual.hideHud or playing then HideHudAndRadarThisFrame() end
            if letterbox then
                DrawRect(0.5, BAR / 2, 1.0, BAR, 0, 0, 0, 255)
                DrawRect(0.5, 1.0 - BAR / 2, 1.0, BAR, 0, 0, 0, 255)
            end
            if Visual.grid and not playing then drawGrid() end
            if Visual.timeScale ~= 1.0 then SetTimeScale(Visual.timeScale) end
            Wait(0)
        else
            Wait(250)
        end
    end
end)
