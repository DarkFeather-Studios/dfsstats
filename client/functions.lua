local HealthTracking = nil
local ArmorTracking = nil

local Stats = {
    Food =      1000000,
    Water =     1000000,
    Stress =          0,
    Armor =           0,
    Health =        200,
}

local MaxStats = {
    Food =      1000000,
    Water =     1000000,
    Stress =    1000000,
    Armor =     GetPlayerMaxArmour(PlayerId()),
    Health =    200,
}

local LastSave = -60000
local drainTimout = 1000 -- milliseconds between drains to water or food.
local lastDrain = GetGameTimer()
local currentTimer = GetGameTimer()
local isStarted = false
local quickFadeTimeout = 15000
local nextQuickFade = GetGameTimer()
local healthDrainTimeout = 5000
local nextHealthDrain = GetGameTimer()
local healthDecrementSteps = 3

--[[ Returns a single stat ]]
function GetStat(Name)
    return Stats[Name]
end


function ModStat(Name, Amount)
    Stats[Name] = Stats[Name] + Amount
end

function GetStatMax(Name)
    return MaxStats[Name]
end

function SetStatMax(Name, Amount)
    MaxStats[Name] = MaxStats[Name] + Amount
end

function ResetStatMaxes()
    MaxStats = {
        Food =      1000000,
        Water =     1000000,
        Stress =    1000000,
        Armor =     GetPlayerMaxArmour(PlayerId()),
        Health =    200,
    }
end

function ResetStats(ToCurrentMaxes)
    if not ToCurrentMaxes then
        Stats = {
            Food =      1000000,
            Water =     1000000,
            Stress =          0,
            Armor =           0,
            Health =        200,
        }
    else
        Stats = {
            Food =      MaxStats.Food,
            Water =     MaxStats.Water,
            Stress =    0,
            Armor =     0,
            Health =    MaxStats.Health,
        }
    end
    SetPedArmour(PlayerPedId(), 0)
    TriggerServerEvent("dfsstat:SaveStats", Stats)
end

function QuickFade()
    if GetGameTimer() >= nextQuickFade then
        Citizen.CreateThread(function()
            TriggerScreenblurFadeIn(3500.0)
            while IsScreenblurFadeRunning() do
                Wait(0)
            end
            TriggerScreenblurFadeOut(3500.0)
        end)
        nextQuickFade = GetGameTimer() + quickFadeTimeout
    end
end

function DrainHealth()
    if GetGameTimer() >= nextHealthDrain then
        local NewHealth = Stats.Health - healthDecrementSteps
        --Citizen.Trace("Setting Health from: " .. GetEntityHealth(PlayerPedId()) .. " to: " .. NewHealth .. "\n")
        Stats.Health = NewHealth
        nextHealthDrain = GetGameTimer() + healthDrainTimeout
    end
end

function FoodCheck()
    if Stats.Food > MaxStats.Food then
        Stats.Food = MaxStats.Food
    end
    if Stats.Food <= 0 then
        if not exports.dfs_deathmanager:IsDead() then
            QuickFade()
            DrainHealth()
        end
    else
        -- We are going to use a time-based drain so that disparity between clients won't matter.
        if currentTimer >= lastDrain then
            if IsPedInAnyVehicle(PlayerPedId(), false) then
                Stats.Food = Stats.Food - 140
            else
                if IsPedSwimming(PlayerPedId()) or IsPedSwimmingUnderWater(PlayerPedId()) then
                    Stats.Food = Stats.Food - 2230 -- ~7.5 Mins of swimming
                elseif IsPedRunning(PlayerPedId()) or IsPedSprinting(PlayerPedId()) then
                    Stats.Food = Stats.Food - 1110 -- ~15 Mins of running
                elseif IsPedWalking(PlayerPedId()) then
                    Stats.Food = Stats.Food - 280 -- ~1 Hour of walking
                else
                    Stats.Food = Stats.Food - 140 -- ~2 Hours standing still
                end
            end
        end
    end
end

function WaterCheck()
    if Stats.Water > MaxStats.Water then
        Stats.Water = MaxStats.Water
    end

    if Stats.Water <= 0 then
        if not exports.dfs_deathmanager:IsDead() then
            QuickFade()
            DrainHealth()
        end
    else
        -- We are going to use a time-based drain so that disparity between clients won't matter.
        if currentTimer >= lastDrain then
            if IsPedInAnyVehicle(PlayerPedId(), false) then
                Stats.Water = Stats.Water - 280
            else
                if IsPedRunning(PlayerPedId()) or IsPedSprinting(PlayerPedId()) then
                    Stats.Water = Stats.Water - 2230 -- ~7.5 Mins of running
                elseif IsPedWalking(PlayerPedId()) then
                    Stats.Water = Stats.Water - 550 -- ~30 Mins of walking
                else
                    Stats.Water = Stats.Water - 280 -- ~1 Hour of standing still
                end
                --Citizen.Trace("Water: " .. Stats.Water .. "\n")
            end
        end
    end
end

function StressCheck()
    Stats.Stress = Stats.Stress + (math.random(5) == 5 and 1 or 0)

    if Stats.Stress > MaxStats.Stress then
        Stats.Stress = MaxStats.Stress
    elseif Stats.Stress <= 0 then
        Stats.Stress = 0
    end
end

function SaveStats()
    if currentTimer >= LastSave + 1000 and isStarted then
        LastSave = GetGameTimer()
        TriggerServerEvent("dfsstat:SaveStats", Stats)
    end
end

function RunDrain()
    -- We are going to use a time-based drain so that disparity between clients won't matter.
    if currentTimer >= lastDrain then
        lastDrain = GetGameTimer() + drainTimout
    end
end

function AddStat(name, amount)
    Stats[name] = Stats[name] + amount
    if Stats[name] < 0 then
        Stats[name] = 0
    end
    if Stats[name] > MaxStats[name] then
        Stats[name] = MaxStats[name]
    end
end

function InitStats()
    exports.dfs:TriggerServerCallback("dfsstats:GetStats", function(StatsTable)
        if (StatsTable == 'null') then
            ResetStats(true)
            Stats.Health = 200
            --Citizen.Trace("Set Health to: " .. Stats.Health .. "\n")
        else
            for k, v in pairs(json.decode(StatsTable)) do
                if Stats[k] and v ~= nil then
                    Stats[k] = v
                    --Citizen.Trace("Loading Stat " .. k .. ": " .. v .. "\n")
                end
            end
            isStarted = true
        end
    end)
end

function ResourceStart(resourceName)
    if resourceName == GetCurrentResourceName() then
        Citizen.CreateThread(MainThread)
        Citizen.CreateThread(StressThread)
    end
end

function SetStat(name, val)
    --Citizen.Trace('Stats: Setting ' .. name .. ' to ' .. val .. '\n')
    for k, v in pairs(Stats) do
        if k == name then
            Stats[k] = val
            break
        end
    end
end

function ReduceStat(statToReduce, amountToReduceBy)
    --Citizen.Trace('Stats: reducing ' .. statToReduce .. ' by ' .. amountToReduceBy .. '\n')
    local newStatVal = GetStat(statToReduce) - amountToReduceBy
    SetStat(statToReduce, newStatVal)
end

function LoopSetup()
    currentTimer = GetGameTimer()
    Stats.Armor = GetPedArmour(PlayerPedId())
end

function OnEat(prop_name)
	if not IsAnimated then
		prop_name = prop_name or 'prop_cs_burger_01'
		IsAnimated = true
		Citizen.CreateThread(function()
			local playerPed = PlayerPedId()
			local x,y,z = table.unpack(GetEntityCoords(playerPed))
			local prop = CreateObject(GetHashKey(prop_name), x, y, z + 0.2, true, true, true)
			local boneIndex = GetPedBoneIndex(playerPed, 18905)
			AttachEntityToEntity(prop, playerPed, boneIndex, 0.12, 0.028, 0.001, 10.0, 175.0, 0.0, true, true, false, true, 1, true)

            TaskPlayAnim(playerPed, 'mp_player_inteat@burger', 'mp_player_int_eat_burger_fp', 8.0, -8, -1, 49, 0, 0, 0, 0)

            Citizen.Wait(3000)
            IsAnimated = false
            ClearPedSecondaryTask(playerPed)
            DeleteObject(prop)
		end)
	end
end

function OnDrink(prop_name)
	if not IsAnimated then
		prop_name = prop_name or 'prop_ld_flow_bottle'
		IsAnimated = true

		Citizen.CreateThread(function()
			local x,y,z = table.unpack(GetEntityCoords(PlayerPedId()))
			local prop = CreateObject(GetHashKey(prop_name), x, y, z + 0.2, true, true, true)
			local boneIndex = GetPedBoneIndex(PlayerPedId(), 18905)
			AttachEntityToEntity(prop, PlayerPedId(), boneIndex, 0.12, 0.028, 0.001, 10.0, 175.0, 0.0, true, true, false, true, 1, true)

            TaskPlayAnim(PlayerPedId(), 'mp_player_intdrink', 'loop_bottle', 1.0, -1.0, 2000, 0, 1, true, true, true)

            Citizen.Wait(3000)
            IsAnimated = false
            ClearPedSecondaryTask(PlayerPedId())
            DeleteObject(prop)
		end)
    end
end

function StressThread()
    while true do
        if Stats.Stress >=  1000000 then
            Citizen.Wait(3000)
            ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 0.16)
        elseif Stats.Stress >= 750000 then
            Citizen.Wait(4000)
            ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 0.12)
        elseif Stats.Stress >= 625000 then
            Citizen.Wait(5000)
            ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 0.07)
        elseif Stats.Stress >= 500000 then
            Citizen.Wait(6000)
            ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 0.03)
        end
        
        Wait(0)
    end
end

function UpdateHealthFromGame()
    Stats.Health = GetEntityHealth(PlayerPedId())
end

--[[ DEBUGGING COMMANDS ]]
RegisterCommand("thirsty", function()
    Stats.Water = 0
end)

RegisterCommand("hungry", function()
    Stats.Food = 0
end)

RegisterCommand("showstats", function()
    Citizen.Trace("Stats:\n\tWater: " .. Stats.Water .. "\n\tFood: " .. Stats.Food .. "\n\tHealth: " .. Stats.Health .. "\n")
end)


Citizen.CreateThread(function() --BUG: The way this function is laid out, players can heal. Say I was just beat with a baseball bat, and now I'm starving to death. As far as
                                --I can tell, the starving will restore my health before ticking down slowly
    
        HealthTracking = Stats.Health
        ArmorTracking = Stats.Armor
        while true do
        if Stats.Health ~= HealthTracking then
            if Stats.Health < 0 then
                Stats.Health = 0
            end
            SetEntityHealth(PlayerPedId(), Stats.Health)
            --print("HP Was "..HealthTracking.." being set to "..Stats.Health)
            --Citizen.Trace("Health changed from: " .. HealthTracking .. " to: " .. Stats.Health .. "\n")
            --Citizen.Trace("Fivem Health: " .. GetEntityHealth(PlayerPedId()) .. "\n")
            HealthTracking = Stats.Health
        end
        if Stats.Armor ~= ArmorTracking then
            SetPedArmour(PlayerPedId(), Stats.Armor)
            --Citizen.Trace("Armor changed from: " .. ArmorTracking .. " to: " .. Stats.Armor .. "\n")
            --Citizen.Trace("Fivem Health: " .. GetEntityHealth(PlayerPedId()) .. "\n")
            ArmorTracking = Stats.Armor
        end
        Wait(0)
    end
end)