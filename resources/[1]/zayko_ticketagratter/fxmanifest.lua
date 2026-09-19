fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Zayko'
description 'zayko_ticketagratter - Tickets a gratter (loterie) pour ESX'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

-- Necessite es_extended (ESX Legacy)
