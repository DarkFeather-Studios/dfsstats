fx_version 'adamant'

game 'gta5'

resource_manifest_version '44febabe-d386-4d18-afbe-5e627f4af937'

dependency 'dfs'

client_scripts {
    "client/functions.lua",
    "client/client.lua"
    --"minimap.lua"
}

exports {
    'GetStat',
    "ModStat",
    "GetStatMax",
    "SetStatMax",
    "ResetStatMaxes",
    "ResetStats"
}

server_scripts{
    '@mysql-async/lib/MySQL.lua',
    "server/server.lua"
}