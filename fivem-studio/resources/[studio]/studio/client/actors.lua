-- Actores: peds, vehículos y props colocados donde apunta la cámara
Actors = { list = {} }

local KINDS = { ped = true, vehicle = true, prop = true }

local function cameraView()
    if Freecam.active then return Freecam.pos, Freecam.rot end
    return GetGameplayCamCoord(), GetGameplayCamRot(2)
end

-- Punto donde mira la cámara (raycast contra mapa, vehículos y objetos)
local function aimPoint()
    local origin, rot = cameraView()
    local dest = origin + Utils.rotToDir(rot) * 60.0
    local ray = StartExpensiveSynchronousShapeTestLosProbe(
        origin.x, origin.y, origin.z, dest.x, dest.y, dest.z, 19, PlayerPedId(), 7)
    local _, hit, coords = GetShapeTestResult(ray)
    local heading = (rot.z + 180.0) % 360.0 -- mirando hacia la cámara
    if hit == 1 or hit == true then return coords, heading end
    return GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 2.0, 0.0), heading
end

local function track(handle, kind, model)
    Actors.list[#Actors.list + 1] = { handle = handle, kind = kind, model = model, frozen = false, anim = nil }
end

function Actors.spawn(kind, model)
    if not KINDS[kind] then return end
    model = tostring(model or ''):gsub('%s', '')
    if model == '' then return end

    local hash = tonumber(model) or GetHashKey(model)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        Studio.notify(('~r~Modelo inválido: %s'):format(model))
        return
    end
    if not Studio.loadModel(hash) then return end

    local p, heading = aimPoint()
    local ent
    if kind == 'ped' then
        ent = CreatePed(4, hash, p.x, p.y, p.z, heading, true, false)
        SetPedRandomComponentVariation(ent, 0)
        SetBlockingOfNonTemporaryEvents(ent, true)
        SetPedFleeAttributes(ent, 0, false)
        SetPedKeepTask(ent, true)
        SetEntityInvincible(ent, true)
    elseif kind == 'vehicle' then
        ent = CreateVehicle(hash, p.x, p.y, p.z + 0.5, heading, true, false)
        SetVehicleOnGroundProperly(ent)
        SetVehicleDirtLevel(ent, 0.0)
        SetVehicleNumberPlateText(ent, 'STUDIO')
    else
        ent = CreateObject(hash, p.x, p.y, p.z, true, false, false)
        SetEntityHeading(ent, heading)
        PlaceObjectOnGroundProperly(ent)
    end
    SetModelAsNoLongerNeeded(hash)

    if ent and ent ~= 0 then track(ent, kind, model) end
end

function Actors.cloneMe()
    local p, heading = aimPoint()
    local ent = ClonePed(PlayerPedId(), true, false, true)
    SetEntityCoords(ent, p.x, p.y, p.z, false, false, false, false)
    SetEntityHeading(ent, heading)
    SetBlockingOfNonTemporaryEvents(ent, true)
    SetEntityInvincible(ent, true)
    track(ent, 'ped', 'clon')
end

-- index 0 = mi personaje
local function pedAt(index)
    if index == 0 then return PlayerPedId() end
    local a = Actors.list[index]
    if a and a.kind == 'ped' and DoesEntityExist(a.handle) then return a.handle, a end
    return nil
end

function Actors.playAnim(index, animIndex)
    local ped, actor = pedAt(index)
    local preset = Config.Animations[animIndex]
    if not ped or not preset then return end
    if not Studio.loadAnimDict(preset.dict) then return end
    ClearPedTasks(ped)
    TaskPlayAnim(ped, preset.dict, preset.anim, 8.0, -8.0, -1, preset.flag or 1, 0.0, false, false, false)
    if actor then actor.anim = preset.label end
end

function Actors.stopAnim(index)
    local ped, actor = pedAt(index)
    if not ped then return end
    ClearPedTasks(ped)
    if actor then actor.anim = nil end
end

function Actors.toggleFreeze(index)
    local a = Actors.list[index]
    if not a or not DoesEntityExist(a.handle) then return end
    a.frozen = not a.frozen
    FreezeEntityPosition(a.handle, a.frozen)
end

local function destroy(a)
    if DoesEntityExist(a.handle) then
        SetEntityAsMissionEntity(a.handle, true, true)
        DeleteEntity(a.handle)
    end
end

function Actors.delete(index)
    local a = Actors.list[index]
    if not a then return end
    destroy(a)
    table.remove(Actors.list, index)
end

function Actors.clear()
    for _, a in ipairs(Actors.list) do destroy(a) end
    Actors.list = {}
end

-- Quita de la lista lo que ya no existe
function Actors.prune()
    for i = #Actors.list, 1, -1 do
        if not DoesEntityExist(Actors.list[i].handle) then table.remove(Actors.list, i) end
    end
end
