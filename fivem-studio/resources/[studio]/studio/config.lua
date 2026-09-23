Config = {}

-- Permiso ACE necesario para usar el estudio (ver server.cfg)
Config.Permission = 'studio.use'

-- Punto de aparición (Legion Square)
Config.Spawn = {
    x = 195.17, y = -933.77, z = 30.69,
    heading = 144.0,
    model = 'mp_m_freemode_01',
}

Config.Freecam = {
    fov = 50.0,          -- FOV inicial
    minFov = 5.0,
    maxFov = 120.0,
    fovStep = 2.0,       -- por cada paso de la rueda del mouse
    speed = 5.0,         -- metros por segundo
    minSpeed = 0.1,
    maxSpeed = 150.0,
    fastMult = 4.0,      -- Shift
    slowMult = 0.2,      -- Alt
    sensitivity = 10.0,  -- sensibilidad del mouse
    rollSpeed = 30.0,    -- grados por segundo (Z / C)
}

Config.Cinematic = {
    maxKeyframes = 200,
    defaultDuration = 3.0, -- segundos hasta el siguiente keyframe
}

Config.World = {
    weather = 'EXTRASUNNY',
    hour = 12,
    minute = 0,
    freezeTime = true,
    msPerGameMinute = 2000, -- si el tiempo no está congelado
}

Config.Weathers = {
    { id = 'EXTRASUNNY', label = 'Soleado' },
    { id = 'CLEAR',      label = 'Despejado' },
    { id = 'NEUTRAL',    label = 'Neutral' },
    { id = 'CLOUDS',     label = 'Nublado' },
    { id = 'OVERCAST',   label = 'Cubierto' },
    { id = 'CLEARING',   label = 'Aclarando' },
    { id = 'SMOG',       label = 'Smog' },
    { id = 'FOGGY',      label = 'Niebla' },
    { id = 'RAIN',       label = 'Lluvia' },
    { id = 'THUNDER',    label = 'Tormenta' },
    { id = 'SNOWLIGHT',  label = 'Nieve ligera' },
    { id = 'SNOW',       label = 'Nieve' },
    { id = 'BLIZZARD',   label = 'Ventisca' },
    { id = 'XMAS',       label = 'Navidad (nieve en el suelo)' },
    { id = 'HALLOWEEN',  label = 'Halloween' },
}

-- Modificadores de timecycle (filtros de color)
Config.Filters = {
    { id = '',                   label = 'Ninguno' },
    { id = 'cinema',             label = 'Cine' },
    { id = 'MP_corona_heist_BW', label = 'Blanco y negro' },
    { id = 'NG_filmic01',        label = 'Filmic 01' },
    { id = 'NG_filmic02',        label = 'Filmic 02' },
    { id = 'NG_filmic03',        label = 'Filmic 03' },
    { id = 'NG_filmic04',        label = 'Filmic 04' },
    { id = 'NG_filmic05',        label = 'Filmic 05' },
    { id = 'NG_filmic06',        label = 'Filmic 06' },
    { id = 'NG_filmic07',        label = 'Filmic 07' },
    { id = 'NG_filmic08',        label = 'Filmic 08' },
    { id = 'NG_filmic09',        label = 'Filmic 09' },
    { id = 'NG_filmic10',        label = 'Filmic 10' },
    { id = 'rply_saturation',    label = 'Saturación' },
    { id = 'rply_contrast',      label = 'Contraste' },
    { id = 'rply_vignette',      label = 'Viñeta' },
    { id = 'rply_brightness',    label = 'Brillo' },
}

-- Animaciones rápidas para actores (flag 1 = en bucle)
Config.Animations = {
    { label = 'Brazos cruzados', dict = 'amb@world_human_hang_out_street@female_arms_crossed@base', anim = 'base', flag = 1 },
    { label = 'Fumar',           dict = 'amb@world_human_smoking@male@male_a@base', anim = 'base', flag = 1 },
    { label = 'Hablar por teléfono', dict = 'amb@world_human_stand_mobile@male@standing@call@base', anim = 'base', flag = 1 },
    { label = 'Apoyado en pared', dict = 'amb@world_human_leaning@male@wall@back@foot_up@base', anim = 'base', flag = 1 },
    { label = 'Sentado (picnic)', dict = 'amb@world_human_picnic@male@base', anim = 'base', flag = 1 },
    { label = 'Manos arriba',    dict = 'missminuteman_1ig_2', anim = 'handsup_base', flag = 49 },
    { label = 'Saludar',         dict = 'gestures@m@standing@casual', anim = 'gesture_hello', flag = 48 },
    { label = 'Bailar',          dict = 'anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity', anim = 'hi_dance_facedj_09_v2_male^1', flag = 1 },
    { label = 'Herido en el suelo', dict = 'combat@damage@writhe', anim = 'writhe_loop', flag = 1 },
}

-- Modelos sugeridos en el panel de actores
Config.QuickModels = {
    ped = { 'mp_m_freemode_01', 'mp_f_freemode_01', 'a_m_y_hipster_01', 'a_f_y_business_01', 's_m_y_cop_01', 'g_m_y_ballasorig_01', 'a_c_rottweiler' },
    vehicle = { 'adder', 'zentorno', 'sultan', 'police', 'bati', 'sanchez', 'maverick' },
    prop = { 'prop_table_03', 'prop_chair_01a', 'prop_barrier_work05', 'prop_mp_cone_01', 'prop_bench_01a', 'prop_ld_suitcase_01' },
}
