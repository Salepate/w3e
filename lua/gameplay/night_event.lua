-- data
local units = {}
local region_map = {}
local empty_group = {}
local daycount = 1
-- private func/callbacks
-- Module
Module("NightEvent",
{
    IsActive = false,
    SetNightEvent = function(active) NightEvent.IsActive = active end,

    -- Spawn Filters
    CombineFilters = function(a --[[bool()]], b --[[bool()]], and_cond --[[boolean]])

        return function()
            if and_cond == nil then
                and_cond = true
            end
            local res_a = a()
            local res_b = b()
            if and_cond then
                return res_a and res_b
            else
                return res_a or res_b
            end
        end
    end,
    
    SpawnFilter = function() return NightEvent.IsActive end,
    DayTwoFilter = function() return daycount >= 2 end,
    DayThreeFilter = function() return daycount >= 3 end,

    RegisterNightCreep = function(spawn)
        local unit = spawn.Alive
        table.insert(units, unit)
        region_map[unit] = spawn.World
    end,

    CreateSpawn = function(count, min_delay, max_delay, region_index, filter)
        if filter == nil then
            filter = NightEvent.SpawnFilter
        else
            filter = NightEvent.CombineFilters(NightEvent.SpawnFilter, filter)
        end
        Respawn.Create(count, min_delay, max_delay, region_index, filter, NightEvent.RegisterNightCreep)
    end,

    GetDay = function()
        return daycount
    end,

    -- increase creep upgrades
    Advance = function()
        daycount = daycount + 1
        for i=1,#UPGRADE_CREEP do
            for j=1,#HOSTILE_FORCES do
                SetPlayerTechResearched(HOSTILE_FORCES[j], UPGRADE_CREEP[i], daycount - 1)
            end
        end
    end,

    ProcessAI = function(unit)
        if GetUnitCurrentOrder(unit) == ORDER_IDLE then
            local worldReg = region_map[unit]
            local playerGrp = WorldRegion.PlayerGroups[worldReg] or empty_group
            if GetRandomInt(1, 6) <= 2 then
                local target = playerGrp[GetRandomInt(1, #playerGrp)]
                IssueTargetOrderById(unit, ORDER_ATTACK, target)
            end
        end
    end,

    DamageNightCreeps = function()
        for i=#units,1,-1 do
            local unit = units[i]
            if GetUnitState(unit, UNIT_STATE_LIFE) <= 0.405 then
                region_map[units[i]] = nil
                table.remove(units, i)
            else
                UnitDamageTarget(unit, unit, 10.0, true, true, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_NORMAL, WEAPON_TYPE_CLAW_HEAVY_SLICE)
            end
        end
    end,

    OnStart = function()
        Clock.Register(function ()
            if not NightEvent.IsActive then
                NightEvent.DamageNightCreeps()
            else
                for i=1,#units do
                    NightEvent.ProcessAI(units[i])
                end
            end
        end, 5.0)
    end
})