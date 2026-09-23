-- Cinemáticas: keyframes de cámara interpolados con Catmull-Rom
Cinematic = {
    keyframes = {}, -- { pos = {x,y,z}, rot = {x,y,z}, fov, duration }
    playing = false,
    settings = {
        ease = 'smooth',   -- 'linear' | 'smooth'
        loop = false,
        letterbox = true,
        record = false,    -- graba un clip del Rockstar Editor
        countdown = 3,
    },
}

local EASE = {
    linear = function(t) return t end,
    smooth = function(t) return t * t * (3 - 2 * t) end,
}

local function toVec(t)
    return vector3(t.x + 0.0, t.y + 0.0, t.z + 0.0)
end

function Cinematic.add(duration)
    if not Freecam.active then
        Studio.notify('Activa la freecam (F6) para añadir keyframes.')
        return
    end
    if #Cinematic.keyframes >= Config.Cinematic.maxKeyframes then
        Studio.notify('~r~Límite de keyframes alcanzado.')
        return
    end
    local p, r = Freecam.pos, Freecam.rot
    Cinematic.keyframes[#Cinematic.keyframes + 1] = {
        pos = { x = p.x, y = p.y, z = p.z },
        rot = { x = r.x, y = r.y, z = r.z },
        fov = Freecam.fov,
        duration = Utils.clamp(Utils.num(duration, Config.Cinematic.defaultDuration), 0.1, 600.0),
    }
    Studio.notify(('Keyframe ~b~#%d~s~ añadido.'):format(#Cinematic.keyframes))
end

function Cinematic.remove(index)
    table.remove(Cinematic.keyframes, index)
end

function Cinematic.clear()
    Cinematic.keyframes = {}
end

function Cinematic.setDuration(index, duration)
    local kf = Cinematic.keyframes[index]
    if kf then kf.duration = Utils.clamp(Utils.num(duration, kf.duration), 0.1, 600.0) end
end

-- Reemplaza el keyframe con la posición actual de la cámara
function Cinematic.update(index)
    local kf = Cinematic.keyframes[index]
    if not kf or not Freecam.active then return end
    local p, r = Freecam.pos, Freecam.rot
    kf.pos = { x = p.x, y = p.y, z = p.z }
    kf.rot = { x = r.x, y = r.y, z = r.z }
    kf.fov = Freecam.fov
end

function Cinematic.jumpTo(index)
    local kf = Cinematic.keyframes[index]
    if not kf then return end
    Freecam.start()
    Freecam.pos = toVec(kf.pos)
    Freecam.rot = toVec(kf.rot)
    Freecam.fov = kf.fov
end

function Cinematic.setSettings(data)
    local s = Cinematic.settings
    if data.ease and EASE[data.ease] then s.ease = data.ease end
    for _, key in ipairs({ 'loop', 'letterbox', 'record' }) do
        if data[key] ~= nil then s[key] = data[key] == true end
    end
    if data.countdown ~= nil then s.countdown = math.floor(Utils.clamp(Utils.num(data.countdown, 3), 0, 10)) end
end

-- Prepara los puntos. El yaw se "desenrolla" para que la cámara gire por el camino corto.
local function buildPath()
    local pts, rots, fovs, durs = {}, {}, {}, {}
    local prevYaw
    for i, kf in ipairs(Cinematic.keyframes) do
        pts[i] = toVec(kf.pos)
        local yaw = kf.rot.z + 0.0
        if prevYaw then
            while yaw - prevYaw > 180.0 do yaw = yaw - 360.0 end
            while yaw - prevYaw < -180.0 do yaw = yaw + 360.0 end
        end
        prevYaw = yaw
        rots[i] = vector3(kf.rot.x + 0.0, kf.rot.y + 0.0, yaw)
        fovs[i] = kf.fov + 0.0
        durs[i] = math.max(0.1, kf.duration)
    end
    return pts, rots, fovs, durs
end

local function sample(list, i, t, n)
    return Utils.catmullRom(list[math.max(i - 1, 1)], list[i], list[i + 1], list[math.min(i + 2, n)], t)
end

function Cinematic.play()
    if Cinematic.playing then return end
    local n = #Cinematic.keyframes
    if n < 2 then
        Studio.notify('Necesitas al menos ~b~2 keyframes~s~.')
        return
    end

    local pts, rots, fovs, durs = buildPath()
    local total = 0.0
    for i = 1, n - 1 do total = total + durs[i] end

    Cinematic.playing = true
    Cinematic.jumpTo(1)

    CreateThread(function()
        local s = Cinematic.settings
        for c = s.countdown, 1, -1 do
            if not Cinematic.playing then break end
            SendNUIMessage({ action = 'countdown', value = c })
            Wait(1000)
        end
        SendNUIMessage({ action = 'countdown', value = 0 })

        while Cinematic.playing do
            if s.record then StartRecording(1) end
            local start = GetGameTimer()
            local ease = EASE[s.ease]

            while Cinematic.playing do
                local u = math.min((GetGameTimer() - start) / 1000.0 / total, 1.0)
                local t = ease(u) * total
                local i = 1
                while i < n - 1 and t > durs[i] do
                    t = t - durs[i]
                    i = i + 1
                end
                local lt = Utils.clamp(t / durs[i], 0.0, 1.0)

                Freecam.pos = sample(pts, i, lt, n)
                Freecam.rot = sample(rots, i, lt, n)
                Freecam.fov = sample(fovs, i, lt, n)

                -- Retroceso para cortar
                if IsDisabledControlJustPressed(0, 177) or IsControlJustPressed(0, 177) then
                    Cinematic.playing = false
                end
                if u >= 1.0 then break end
                Wait(0)
            end

            if s.record then StopRecordingAndSaveClip() end
            if not s.loop then break end
        end

        Cinematic.playing = false
        Freecam.refreshHud()
        Studio.pushState()
    end)
end

function Cinematic.stop()
    Cinematic.playing = false
end
