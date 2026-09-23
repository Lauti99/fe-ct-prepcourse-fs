local FC = Config.Freecam

Freecam = {
    active = false,
    cam = nil,
    pos = vector3(0.0, 0.0, 0.0),
    rot = vector3(0.0, 0.0, 0.0), -- x = pitch, y = roll, z = yaw
    fov = FC.fov,
    speed = FC.speed,
    dof = { enabled = false, near = 1.0, far = 15.0, strength = 1.0 },
}

-- Controles que siguen funcionando con la freecam activa
local ENABLED_CONTROLS = {
    199, 200, -- pausa / ESC
    245,      -- chat (T)
    249,      -- push to talk (N)
}

local lastHud = ''

local function applyCam()
    local cam, p, r = Freecam.cam, Freecam.pos, Freecam.rot
    SetCamCoord(cam, p.x, p.y, p.z)
    SetCamRot(cam, r.x, r.y, r.z, 2)
    SetCamFov(cam, Freecam.fov)
    SetFocusPosAndVel(p.x, p.y, p.z, 0.0, 0.0, 0.0)

    local dof = Freecam.dof
    SetCamUseShallowDofMode(cam, dof.enabled)
    if dof.enabled then
        SetCamNearDof(cam, dof.near)
        SetCamFarDof(cam, dof.far)
        SetCamDofStrength(cam, dof.strength)
        SetUseHiDof()
    end
end

local function handleInput(dt)
    -- Mirar
    local lx = GetDisabledControlNormal(0, 1)
    local ly = GetDisabledControlNormal(0, 2)
    local sens = FC.sensitivity * (Freecam.fov / FC.fov) -- más fino con zoom
    local pitch = Utils.clamp(Freecam.rot.x - ly * sens, -89.0, 89.0)
    local yaw = (Freecam.rot.z - lx * sens) % 360.0
    local roll = Freecam.rot.y

    -- Roll: Z / C, reset: X
    if IsDisabledControlPressed(0, 20) then roll = roll - FC.rollSpeed * dt end
    if IsDisabledControlPressed(0, 26) then roll = roll + FC.rollSpeed * dt end
    if IsDisabledControlJustPressed(0, 73) then roll = 0.0 end
    Freecam.rot = vector3(pitch, roll, yaw)

    -- FOV: rueda del mouse
    if IsDisabledControlJustPressed(0, 241) then
        Freecam.fov = Utils.clamp(Freecam.fov - FC.fovStep, FC.minFov, FC.maxFov)
    elseif IsDisabledControlJustPressed(0, 242) then
        Freecam.fov = Utils.clamp(Freecam.fov + FC.fovStep, FC.minFov, FC.maxFov)
    end

    -- Velocidad base: RePág / AvPág
    if IsDisabledControlJustPressed(0, 10) then
        Freecam.speed = Utils.clamp(Freecam.speed * 1.25, FC.minSpeed, FC.maxSpeed)
    elseif IsDisabledControlJustPressed(0, 11) then
        Freecam.speed = Utils.clamp(Freecam.speed / 1.25, FC.minSpeed, FC.maxSpeed)
    end

    -- Movimiento
    local mult = 1.0
    if IsDisabledControlPressed(0, 21) then mult = FC.fastMult
    elseif IsDisabledControlPressed(0, 19) then mult = FC.slowMult end

    local fwd = Utils.rotToDir(Freecam.rot)
    local ryaw = math.rad(yaw)
    local right = vector3(math.cos(ryaw), math.sin(ryaw), 0.0)
    local up = vector3(0.0, 0.0, 1.0)
    local move = vector3(0.0, 0.0, 0.0)

    if IsDisabledControlPressed(0, 32) then move = move + fwd end   -- W
    if IsDisabledControlPressed(0, 33) then move = move - fwd end   -- S
    if IsDisabledControlPressed(0, 35) then move = move + right end -- D
    if IsDisabledControlPressed(0, 34) then move = move - right end -- A
    if IsDisabledControlPressed(0, 22) or IsDisabledControlPressed(0, 38) then move = move + up end -- Espacio / E
    if IsDisabledControlPressed(0, 36) or IsDisabledControlPressed(0, 44) then move = move - up end -- Ctrl / Q

    Freecam.pos = Freecam.pos + move * (Freecam.speed * mult * dt)
end

local function updateHud()
    local hud = ('%.1f|%.1f|%.1f'):format(Freecam.speed, Freecam.fov, Freecam.rot.y)
    if hud ~= lastHud then
        lastHud = hud
        SendNUIMessage({
            action = 'hud', visible = true,
            speed = Freecam.speed, fov = Freecam.fov, roll = Freecam.rot.y,
        })
    end
end

function Freecam.start()
    if Freecam.active then return end
    local ped = PlayerPedId()
    local camRot = GetGameplayCamRot(2)

    Freecam.pos = GetGameplayCamCoord()
    Freecam.rot = vector3(camRot.x, 0.0, camRot.z)
    Freecam.cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    applyCam()
    RenderScriptCams(true, false, 0, true, true)
    FreezeEntityPosition(ped, true)
    Freecam.active = true
    lastHud = ''

    CreateThread(function()
        while Freecam.active do
            DisableAllControlActions(0)
            for _, c in ipairs(ENABLED_CONTROLS) do EnableControlAction(0, c, true) end

            if not Studio.uiOpen and not Cinematic.playing then
                handleInput(GetFrameTime())
            end
            applyCam()
            if not Cinematic.playing then updateHud() end
            Wait(0)
        end
    end)
end

function Freecam.stop()
    if not Freecam.active then return end
    Freecam.active = false
    RenderScriptCams(false, false, 0, true, true)
    DestroyCam(Freecam.cam, false)
    Freecam.cam = nil
    ClearFocus()
    FreezeEntityPosition(PlayerPedId(), false)
    SendNUIMessage({ action = 'hud', visible = false })
end

-- Fuerza a reenviar el HUD (p. ej. al terminar una cinemática)
function Freecam.refreshHud()
    lastHud = ''
end

function Freecam.toggle()
    if Freecam.active then Freecam.stop() else Freecam.start() end
end

function Freecam.set(data)
    if data.fov then Freecam.fov = Utils.clamp(Utils.num(data.fov, Freecam.fov), FC.minFov, FC.maxFov) end
    if data.speed then Freecam.speed = Utils.clamp(Utils.num(data.speed, Freecam.speed), FC.minSpeed, FC.maxSpeed) end
    if data.roll then Freecam.rot = vector3(Freecam.rot.x, Utils.clamp(Utils.num(data.roll, 0.0), -180.0, 180.0), Freecam.rot.z) end
    if type(data.dof) == 'table' then
        local d = Freecam.dof
        if data.dof.enabled ~= nil then d.enabled = data.dof.enabled == true end
        d.near = Utils.clamp(Utils.num(data.dof.near, d.near), 0.0, 500.0)
        d.far = Utils.clamp(Utils.num(data.dof.far, d.far), d.near, 1000.0)
        d.strength = Utils.clamp(Utils.num(data.dof.strength, d.strength), 0.0, 1.0)
    end
end

-- Lleva el personaje del jugador a la posición de la cámara
function Freecam.bringPlayer()
    if not Freecam.active then return end
    local ped = PlayerPedId()
    SetEntityCoords(ped, Freecam.pos.x, Freecam.pos.y, Freecam.pos.z - 1.0, false, false, false, false)
    SetEntityHeading(ped, Freecam.rot.z)
end
