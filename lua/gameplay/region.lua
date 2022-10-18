-- Data
local MAX_RETRY_ATTEMPTS = 5
local region_counters = {}
local region_spawns = {}
local subtriggers = {}
local last_region_index = 1
-- funcs/callbacks
local   get_region_index, enable_region, 
        disable_region, survivor_hook,
        remove_from_group

local on_survivor_enter_region, on_survivor_leave_region
local visited = {} -- used to fast forward time for first visit
local survivor_map = {}
-- Module
Module("WorldRegion",
{
    PlayerGroups = {}, -- [[  map<region_index, array<player_handle>> ]]

    SetWorld = function(worldzone)
        last_region_index = worldzone
    end,
    GetWorldZone = function()
        return last_region_index
    end,

    CountPlayer = function(worldzone)
        return region_counters[worldzone] or 0
    end,

    RemoveSurvivor = function(unit)
        if survivor_map[unit] then
            local reg = survivor_map[unit]
            local group = WorldRegion.PlayerGroups[reg]
            region_counters[reg] = region_counters[reg] - 1
            survivor_map[unit] = nil
            remove_from_group(group, unit)
            if region_counters[reg] == 0 then
                disable_region(reg)
            end
        end
    end,

    GetRandomSurvivor = function(worldzone, excludePlayer)
        local group = WorldRegion.PlayerGroups[worldzone]

        if false then --#group == 1 then
            return group[1]
        else
            local attempts = MAX_RETRY_ATTEMPTS
            local player = group[1]
            while attempts > 0 do
                player = group[GetRandomInt(1, #group)]
                attempts = attempts - 1
                if player ~= excludePlayer then
                    break
                end
            end
            return player
        end
    end,

    OnStart = function()
        for i=1,#Globals.RegionArea do
            local trg_regions_enter = CreateTrigger()
            local trg_regions_exit = CreateTrigger()
            TriggerRegisterEnterRectSimple(trg_regions_enter, Globals.RegionArea[i])
            TriggerRegisterLeaveRectSimple(trg_regions_exit, Globals.RegionArea[i])
            TriggerAddAction(trg_regions_enter, survivor_hook(on_survivor_enter_region, GetTriggerUnit, Globals.RegionArea[i]))
            TriggerAddAction(trg_regions_exit, survivor_hook(on_survivor_leave_region, GetTriggerUnit, Globals.RegionArea[i]))
            table.insert(subtriggers, trg_regions_enter)
            table.insert(subtriggers, trg_regions_exit)
        end
    end
})

get_region_index = function(whichRegion)
    for i=1,#Globals.RegionArea do
        if Globals.RegionArea[i] == whichRegion then
            return i
        end
    end
    return 0
end

enable_region = function(region_index)
    local trig = Globals.RegionScript[region_index] or nil
    last_region_index = region_index
    if not visited[region_index] then
        if trig ~= nil then
            TriggerExecute(trig)
        end
        visited[region_index] = true
        Respawn.FastForward(30)
    end
    Respawn.EnableWorldzone(region_index)
end

disable_region = function(region_index)
    Respawn.DisableWorldzone(region_index, true)
end

survivor_hook = function(callback, unit_invoke, whichRegion)
    return function()
        local unit = unit_invoke()
        if not IsSurvivor(unit) then
            return
        end
        callback(unit, whichRegion)
    end
end

on_survivor_enter_region = function(unit, whichRegion)
    local reg = get_region_index(whichRegion)
    if WorldRegion.PlayerGroups[reg] == nil then
        WorldRegion.PlayerGroups[reg] = {}
    end
    local group = WorldRegion.PlayerGroups[reg]
    
    region_counters[reg] = (region_counters[reg] or 0) + 1
    survivor_map[unit] = reg

    table.insert(group, unit)
    if region_counters[reg] == 1 then
        enable_region(reg)
    end
end

on_survivor_leave_region = function(unit, whichRegion)
    local reg = get_region_index(whichRegion)
    local group = WorldRegion.PlayerGroups[reg]
    region_counters[reg] = region_counters[reg] - 1
    survivor_map[unit] = nil
    remove_from_group(group, unit)
    if region_counters[reg] == 0 then
        disable_region(reg)
    end
end

remove_from_group = function(group, unit)
    local idx = getIndexHandle(group, unit)

    if idx ~= 0 then
        table.remove(group, getIndexHandle(group, unit))
    end
end