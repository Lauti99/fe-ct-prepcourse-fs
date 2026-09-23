fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'studio'
description 'Studio: freecam, cinemáticas, modo foto, control de mundo y actores para creación de contenido'
version '0.1.0'

shared_scripts {
    'config.lua',
    'shared/utils.lua',
}

client_scripts {
    'client/main.lua',
    'client/freecam.lua',
    'client/visual.lua',
    'client/cinematic.lua',
    'client/world.lua',
    'client/actors.lua',
    'client/ui.lua',
}

server_scripts {
    'server/main.lua',
    'server/world.lua',
    'server/scenes.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}

dependency 'spawnmanager'
