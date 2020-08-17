--[[ EVENTS ]]
RegisterNetEvent("esx_status:add")
RegisterNetEvent('esx_basicneeds:onEat')
RegisterNetEvent('esx_basicneeds:onDrink')
RegisterNetEvent('esx_status:set')
RegisterNetEvent('dfs_stats:takeDamage')

--[[ HANDLERS ]]
AddEventHandler("esx_status:add", function(name, amount)
    AddStat(name, amount)
end)
AddEventHandler("kashacters:PlayerSpawned", function()
    InitStats()
end)
AddEventHandler('esx_basicneeds:onEat', function(propName)
    OnEat(propName)
end)
AddEventHandler('esx_basicneeds:onDrink', function(propName)
    OnDrink(propName)
end)
AddEventHandler("onClientResourceStart", function(resourceName)
    ResourceStart(resourceName)
end)
AddEventHandler('esx_status:set', function(name, val)
	SetStat(name, val)
end)
AddEventHandler("dfsstats:UpdateHealthDisplay", function()
    UpdateHealthFromGame()
end)


--[[ MAIN THREAD ]]
function MainThread()
    RequestAnimDict('mp_player_intdrink')
    RequestAnimDict('mp_player_inteat@burger')

    while true do
        LoopSetup()
        FoodCheck()
        WaterCheck()
        StressCheck()
        SaveStats()
        RunDrain()
        Wait(0)
    end

end