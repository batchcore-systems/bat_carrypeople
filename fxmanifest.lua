fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

author 'batchcore systems - mattibat'
description 'Modern carry system with type selection and optional UI (ESX/QBCore/OX compatible)'
version '1.0.0'

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/styles.css',
    'ui/app.js',
    'ui/img/*.png'
}

shared_scripts {
    'shared/config.lua',
    'shared/bridge.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}