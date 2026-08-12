fx_version "cerulean"
game "gta5"
lua54 "yes"

author "Le0n"
description "Ped appearance backend for FiveM - components, props, overlays, tattoos and hair fades."
version "1.0.0"

files {
    "locales/*.json"
}

-- NOTE: files are listed in dependency order and hang themselves onto the global
-- `Skin` namespace. There is no module `require` because that is an ox_lib
-- feature and this resource is deliberately dependency-free.
shared_scripts {
    "config.lua",
    "shared/constants.lua",
    "shared/path.lua",
    "shared/schema.lua"
}

client_scripts {
    "client/init.lua",
    "client/collections.lua",
    "client/clothing.lua",
    "client/ped.lua",
    "client/head.lua",
    "client/hair.lua",
    "client/components.lua",
    "client/tattoos.lua",
    "client/apply.lua",
    "client/read.lua",
    "client/sync.lua",
    "client/main.lua"
}

server_scripts {
    "server/init.lua",
    "server/sync.lua",
    "server/main.lua"
}
