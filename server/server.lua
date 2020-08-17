AddEventHandler("onServerResourceStart", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        exports.dfs:RegisterServerCallback("dfsstats:GetStats", function(playerId)
            return MySQL.Sync.fetchScalar("SELECT `status` FROM `users` WHERE `user_id` = "..exports.dfs:GetTheirIdentifiers(playerId).UserID)
        end)
    end
end)

local PlayerStats = {}
RegisterNetEvent("dfsstat:SaveStats")
AddEventHandler("dfsstat:SaveStats", function(StatsTable)
    PlayerStats[source] = StatsTable
end)

Citizen.CreateThread(function()
    while true do
        for PlayerId, Stats in pairs(PlayerStats) do
            if Stats then
                MySQL.Async.execute("UPDATE `users` SET `status` = '"..json.encode(Stats).."' WHERE `user_id` = "..exports.dfs:GetTheirIdentifiers(PlayerId).UserID)
            end
        end
        Wait(60000)
    end
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    MySQL.Async.execute("UPDATE `users` SET `status` = '"..json.encode(PlayerStats[src]).."' WHERE `user_id` = "..exports.dfs:GetTheirIdentifiers(src).UserID)
    PlayerStats[src] = nil
end)