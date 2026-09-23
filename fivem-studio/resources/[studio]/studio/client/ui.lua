-- Panel NUI, comandos y teclas
function Studio.getState()
    Actors.prune()

    local keyframes = {}
    for i, kf in ipairs(Cinematic.keyframes) do
        keyframes[i] = { fov = kf.fov, duration = kf.duration }
    end

    local actors = {}
    for i, a in ipairs(Actors.list) do
        actors[i] = { kind = a.kind, model = a.model, frozen = a.frozen, anim = a.anim }
    end

    return {
        freecam = {
            active = Freecam.active,
            fov = Freecam.fov,
            speed = Freecam.speed,
            roll = Freecam.rot.y,
            dof = Freecam.dof,
        },
        cine = {
            playing = Cinematic.playing,
            settings = Cinematic.settings,
            keyframes = keyframes,
        },
        visual = {
            hideHud = Visual.hideHud,
            letterbox = Visual.letterbox,
            grid = Visual.grid,
            hidePlayer = Visual.hidePlayer,
            filter = Visual.filter,
            filterStrength = Visual.filterStrength,
            timeScale = Visual.timeScale,
        },
        world = GlobalState.studioWorld,
        actors = actors,
        scenes = Studio.scenes,
    }
end

local function presets()
    local anims = {}
    for i, a in ipairs(Config.Animations) do anims[i] = a.label end
    return {
        weathers = Config.Weathers,
        filters = Config.Filters,
        animations = anims,
        models = Config.QuickModels,
        freecam = Config.Freecam,
        defaultDuration = Config.Cinematic.defaultDuration,
    }
end

function Studio.pushState()
    if Studio.uiOpen then
        SendNUIMessage({ action = 'state', state = Studio.getState() })
    end
end

function Studio.openUI()
    if Studio.uiOpen or not Studio.canUse() then return end
    Studio.uiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', state = Studio.getState(), presets = presets() })
    TriggerServerEvent('studio:requestScenes')
end

function Studio.closeUI()
    if not Studio.uiOpen then return end
    Studio.uiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

-- Comandos + teclas (se pueden cambiar en Ajustes > Asignación de teclas > FiveM)
RegisterCommand('studio', function()
    if Studio.uiOpen then Studio.closeUI() else Studio.openUI() end
end, false)
RegisterKeyMapping('studio', 'Studio: abrir panel', 'keyboard', 'F5')

RegisterCommand('freecam', function()
    if Studio.canUse() then Freecam.toggle() end
end, false)
RegisterKeyMapping('freecam', 'Studio: freecam', 'keyboard', 'F6')

RegisterCommand('keyframe', function(_, args)
    if Studio.canUse() then Cinematic.add(args[1]) end
end, false)
RegisterKeyMapping('keyframe', 'Studio: añadir keyframe', 'keyboard', 'K')

RegisterCommand('cine', function()
    if not Studio.canUse() then return end
    if Cinematic.playing then Cinematic.stop() else Cinematic.play() end
end, false)
RegisterKeyMapping('cine', 'Studio: reproducir / parar cinemática', 'keyboard', 'F7')

-- Callbacks del panel: todos responden con el estado actualizado
local function on(name, fn)
    RegisterNUICallback(name, function(data, cb)
        if name ~= 'close' and not Studio.allowed then return cb(Studio.getState()) end
        local ok, err = pcall(fn, type(data) == 'table' and data or {})
        if not ok then print(('[studio] error en %s: %s'):format(name, err)) end
        cb(Studio.getState())
    end)
end

on('close', function() Studio.closeUI() end)

on('freecam:toggle', function() Freecam.toggle() end)
on('freecam:set', function(d) Freecam.set(d) end)
on('freecam:bringPlayer', function() Freecam.bringPlayer() end)

on('cine:add', function(d) Cinematic.add(d.duration) end)
on('cine:remove', function(d) Cinematic.remove(math.floor(Utils.num(d.index, 0))) end)
on('cine:update', function(d) Cinematic.update(math.floor(Utils.num(d.index, 0))) end)
on('cine:goto', function(d) Cinematic.jumpTo(math.floor(Utils.num(d.index, 0))) end)
on('cine:duration', function(d) Cinematic.setDuration(math.floor(Utils.num(d.index, 0)), d.duration) end)
on('cine:clear', function() Cinematic.clear() end)
on('cine:settings', function(d) Cinematic.setSettings(d) end)
on('cine:play', function()
    Studio.closeUI()
    Cinematic.play()
end)
on('cine:stop', function() Cinematic.stop() end)

on('scene:save', function(d)
    if #Cinematic.keyframes < 2 then
        Studio.notify('Necesitas al menos ~b~2 keyframes~s~ para guardar.')
        return
    end
    TriggerServerEvent('studio:saveScene', d.name, Cinematic.keyframes)
end)
on('scene:load', function(d) TriggerServerEvent('studio:loadScene', d.name) end)
on('scene:delete', function(d) TriggerServerEvent('studio:deleteScene', d.name) end)

on('visual:set', function(d) Visual.set(d) end)

on('world:set', function(d) TriggerServerEvent('studio:setWorld', d) end)
on('world:clearArea', function() World.clearArea() end)

on('actor:spawn', function(d) Actors.spawn(d.kind, d.model) end)
on('actor:clone', function() Actors.cloneMe() end)
on('actor:anim', function(d) Actors.playAnim(math.floor(Utils.num(d.target, 0)), math.floor(Utils.num(d.anim, 0))) end)
on('actor:stopAnim', function(d) Actors.stopAnim(math.floor(Utils.num(d.target, 0))) end)
on('actor:freeze', function(d) Actors.toggleFreeze(math.floor(Utils.num(d.index, 0))) end)
on('actor:delete', function(d) Actors.delete(math.floor(Utils.num(d.index, 0))) end)
on('actor:clear', function() Actors.clear() end)

-- Escenas desde el servidor
RegisterNetEvent('studio:scenes', function(list)
    Studio.scenes = type(list) == 'table' and list or {}
    Studio.pushState()
end)

RegisterNetEvent('studio:sceneData', function(name, keyframes)
    if type(keyframes) ~= 'table' then return end
    Cinematic.stop()
    Cinematic.keyframes = keyframes
    Studio.notify(('Escena ~b~%s~s~ cargada (%d keyframes).'):format(name, #keyframes))
    Studio.pushState()
end)

RegisterNetEvent('studio:notify', function(msg)
    Studio.notify(msg)
end)

-- Limpieza al parar el recurso
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    Cinematic.stop()
    Freecam.stop()
    Visual.reset()
    Actors.clear()
    if Studio.uiOpen then SetNuiFocus(false, false) end
end)
