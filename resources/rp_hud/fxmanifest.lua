fx_version 'cerulean'
game 'gta5'

name 'rp_hud'
description 'Menu F5 + inventaire (ox_inventory) + faim/soif corriges'
author 'ezezeeq'
version '1.0.0'

shared_script 'config.lua'

client_scripts {
    'client/menu.lua',
    'client/needs.lua'
}

server_scripts {
    'server/needs.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

lua54 'yes'
