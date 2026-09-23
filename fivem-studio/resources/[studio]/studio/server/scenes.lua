-- Escenas (rutas de cámara) guardadas en data/scenes.json
local RES = GetCurrentResourceName()
local FILE = 'data/scenes.json'

local scenes = json.decode(LoadResourceFile(RES, FILE) or '{}') or {}

local function persist()
    SaveResourceFile(RES, FILE, json.encode(scenes, { indent = true }), -1)
end

local function sceneList()
    local list = {}
    for name, scene in pairs(scenes) do
        list[#list + 1] = { name = name, author = scene.author, keyframes = #scene.keyframes, updated = scene.updated }
    end
    table.sort(list, function(a, b) return a.name:lower() < b.name:lower() end)
    return list
end

local function cleanName(name)
    if type(name) ~= 'string' then return nil end
    name = name:gsub('^%s+', ''):gsub('%s+$', '')
    if #name < 1 or #name > 40 or not name:match('^[%w%s%-_]+$') then return nil end
    return name
end

local function vec(t)
    if type(t) ~= 'table' then return nil end
    return { x = Utils.num(t.x, 0.0), y = Utils.num(t.y, 0.0), z = Utils.num(t.z, 0.0) }
end

local function sanitize(keyframes)
    if type(keyframes) ~= 'table' then return nil end
    local out = {}
    for _, kf in ipairs(keyframes) do
        if #out >= Config.Cinematic.maxKeyframes then break end
        if type(kf) == 'table' then
            local pos, rot = vec(kf.pos), vec(kf.rot)
            if pos and rot then
                out[#out + 1] = {
                    pos = pos,
                    rot = rot,
                    fov = Utils.clamp(Utils.num(kf.fov, Config.Freecam.fov), 1.0, 130.0),
                    duration = Utils.clamp(Utils.num(kf.duration, Config.Cinematic.defaultDuration), 0.1, 600.0),
                }
            end
        end
    end
    if #out < 2 then return nil end
    return out
end

RegisterNetEvent('studio:requestScenes', function()
    local src = source
    if not Studio.isAllowed(src) then return end
    TriggerClientEvent('studio:scenes', src, sceneList())
end)

RegisterNetEvent('studio:saveScene', function(name, keyframes)
    local src = source
    if not Studio.isAllowed(src) then return end
    name = cleanName(name)
    local clean = sanitize(keyframes)
    if not name then
        return TriggerClientEvent('studio:notify', src, '~r~Nombre inválido (letras, números, espacios, - y _; máx. 40).')
    end
    if not clean then
        return TriggerClientEvent('studio:notify', src, '~r~La escena necesita al menos 2 keyframes válidos.')
    end

    scenes[name] = { keyframes = clean, author = GetPlayerName(src), updated = os.time() }
    persist()
    TriggerClientEvent('studio:notify', src, ('Escena ~b~%s~s~ guardada.'):format(name))
    TriggerClientEvent('studio:scenes', -1, sceneList())
end)

RegisterNetEvent('studio:loadScene', function(name)
    local src = source
    if not Studio.isAllowed(src) then return end
    local scene = type(name) == 'string' and scenes[name]
    if scene then TriggerClientEvent('studio:sceneData', src, name, scene.keyframes) end
end)

RegisterNetEvent('studio:deleteScene', function(name)
    local src = source
    if not Studio.isAllowed(src) or type(name) ~= 'string' or not scenes[name] then return end
    scenes[name] = nil
    persist()
    TriggerClientEvent('studio:scenes', -1, sceneList())
end)
