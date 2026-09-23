Utils = {}

function Utils.clamp(v, min, max)
    if v < min then return min end
    if v > max then return max end
    return v
end

function Utils.lerp(a, b, t)
    return a + (b - a) * t
end

-- Catmull-Rom: funciona con números y con vector3 (el vector siempre a la izquierda)
function Utils.catmullRom(p0, p1, p2, p3, t)
    local t2, t3 = t * t, t * t * t
    return (p1 * 2
        + (p2 - p0) * t
        + (p0 * 2 - p1 * 5 + p2 * 4 - p3) * t2
        + (p1 * 3 - p0 - p2 * 3 + p3) * t3) * 0.5
end

-- Rotación (grados, orden 2) -> vector de dirección
function Utils.rotToDir(rot)
    local rx, rz = math.rad(rot.x), math.rad(rot.z)
    local c = math.abs(math.cos(rx))
    return vector3(-math.sin(rz) * c, math.cos(rz) * c, math.sin(rx))
end

function Utils.findById(list, id)
    for _, item in ipairs(list) do
        if item.id == id then return item end
    end
    return nil
end

-- Número finito o valor por defecto
function Utils.num(v, default)
    v = tonumber(v)
    if not v or v ~= v or v == math.huge or v == -math.huge then return default end
    return v
end
