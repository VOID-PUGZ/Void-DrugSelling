fx_version 'cerulean'
game 'gta5'

author 'Void Scripts'
description 'Drug Selling System with Advanced Features'
version '1.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    '@ox_lib/init.lua',
    'shared/config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

dependencies {
    'ox_lib',
    'ox_inventory',
    'ox_target'
}

lua54 'yes'
