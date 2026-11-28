fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

name 'MULTIcatalog'
author 'RINGO (RINGOscripting)'    -- founder of MULTIcore
description 'MULTIcore mail-order catalog: order everyday goods, pay at once, collect the parcel at the post office you picked. GPL v3.'
version '0.1.1'
license 'GPL-3.0'

ui_page 'html/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    '@MULTIcore/lib/api.lua',      -- MC.* (docs/API.md)
    '@MULTIcore/shared/i18n.lua',  -- _L('key')
    'config.lua',
    'config/*.lua',
    'locales/*.lua',
}

client_scripts {
    '@MULTIcore/lib/interact.lua', -- MULTItarget, with hold-key prompts as fallback
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

files {
    'html/index.html',
    'html/app.js',
    'html/style.css',
    'html/custom.css',
}

dependencies {
    'MULTIcore',
    'MULTItarget',   -- MULTIcore's target system (every MULTI script needs it)
    'MULTIinventory',
    'oxmysql',
    'ox_lib',
}
