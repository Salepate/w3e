-- data
local spawn_type = 0
local active_spawns = {}
local region_spawns = {}
local handle_hashmap = {}
local active_worldzones = {}
local get_timefactor
-- private funcs/events
local   on_tick, on_item_pickup, on_mob_death, default_filter,
        get_handle, spawn_handle, reset_resource, reset_resource_index

Module("Respawn", {
    Unit = 1,
    Item = 2,

    FastForward = function(time --[[number in seconds]], worldzone)
        for i=1,#active_spawns do
            local spawn = active_spawns[i]
            local valid_zone = worldzone == nil or worldzone == spawn.World
            if not active_spawns[i].Alive and active_spawns[i].IsActive() and valid_zone then
                spawn.Clock = math.max(0, spawn.Clock - time)
            end
        end
    end,

    SetRegions = function(count) -- work if region module included
        local worldzone = 1

        if W3E.HasModule("WorldRegion") then
            worldzone = WorldRegion.GetWorldZone()
        end

        region_spawns[worldzone] = region_spawns[worldzone] or {}
        local mainRegion = region_spawns[worldzone]

        if count == nil then
            count = #Globals.SpawnRegions
        end
        for i=1,count do
            table.insert(mainRegion, Globals.SpawnRegions[i])
        end
    end,

    EnableWorldzone = function(worldzone)
        active_worldzones[worldzone] = true
    end,

    DisableWorldzone = function(worldzone, immediate_cull)
        active_worldzones[worldzone] = false
        
        for i=#active_spawns,1,-1 do
            local spawn = active_spawns[i]
            if spawn.World == worldzone then
                if immediate_cull and spawn.Alive ~= false then
                    handle_hashmap[spawn.Alive] = nil
                    if spawn.Type == Respawn.Unit then
                        RemoveUnit(spawn.Alive)
                    elseif spawn.Type == Respawn.Item then
                        RemoveItem(spawn.Alive)
                    end
                    reset_resource_index(i)
                end
            end
        end
    end,

    -- Disable a region (remove all data)
    ClearRegion = function(worldzone_index, immediate_cull)
        for i=#active_spawns,1,-1 do
            local spawn = active_spawns[i]
            if spawn.World == worldzone_index then
                table.remove(active_spawns, i)

                if immediate_cull and spawn.Alive ~= false then
                    handle_hashmap[spawn.Alive] = nil
                    if spawn.Type == Respawn.Unit then
                        RemoveUnit(spawn.Alive)
                    elseif spawn.Type == Respawn.Item then
                        -- TODO: Bugged atm
                        RemoveItem(spawn.Alive)
                    end
                    if spawn.Clean then
                        RemoveRect(spawn.Region)
                    end
                end
            end
        end
    end,

    SetType = function(type --[[ int]] )
        spawn_type = type
    end,

    CreateFromDestructible = function(count --[[ int ]], min_period --[[real]], 
        max_period --[[real]], size --[[ rect size]], active_filter --[[bool(spawn_data)]], spawn_callback --[[void(unit handle)]])

        local worldzone = 1

        if W3E.HasModule("WorldRegion") then
            worldzone = WorldRegion.GetWorldZone()
        end

        local destruct = GetEnumDestructable()
        local desReg = CreateRegion()
        local x = GetDestructableX(destruct)
        local y = GetDestructableY(destruct)
        local desRect = Rect(x - size / 2 , y - size / 2, x + size / 2, y + size / 2)
        RegionAddRect(desReg, desRect)
        RemoveDestructable(destruct)

        for i=1,count do
            local spawn_data = 
            {
                Type = spawn_type,
                Period = { min_period, max_period },
                Clock = GetRandomReal(min_period, max_period),
                EntityHandle = get_handle(),
                Region = desRect,
                Owner = Globals.Input_Player,
                Alive = false,
                IsActive = active_filter or default_filter,
                Callback = spawn_callback,
                World = worldzone,
            }
            table.insert(active_spawns, spawn_data)
        end
    end,

    Create = function(count --[[ int ]], min_period --[[real]], 
        max_period --[[real]], sub_region_index, --[[optional, if none, random]]
        active_filter --[[bool(spawn_data)]],
        spawn_callback --[[void(unit handle)]])
        local target_region

        local worldzone = 1
        if W3E.HasModule("WorldRegion") then
            worldzone = WorldRegion.GetWorldZone()
        end

        if sub_region_index then
            local region = region_spawns[worldzone]
            target_region = region[sub_region_index]
        end

        for i=1,count do
            local spawn_data = 
            {
                Type = spawn_type,
                Period = { min_period, max_period },
                Clock = GetRandomReal(min_period, max_period),
                EntityHandle = get_handle(),
                Region = target_region or Globals.Input_Region,
                Owner = Globals.Input_Player,
                Alive = false,
                IsActive = active_filter or default_filter,
                Callback = spawn_callback,
                World = worldzone,
            }
            table.insert(active_spawns, spawn_data)
        end
    end,
    
    OnStart = function()
        Clock.Register(on_tick, 0.5)
        Enemy.ListenEvent(on_mob_death, Enemy.DeathEvent)
        Item.ListenEvent(on_item_pickup, Item.PickUpEvent)
        Item.ListenEvent(on_item_pickup, Item.StackEvent)
        get_timefactor = PlayerScale.GetTimeFactor
    end
})

-- private implementation
default_filter = function () return true end
get_handle = function()
    if spawn_type == Respawn.Unit then
        return Globals.Input_UnitClass
    elseif spawn_type == Respawn.Item then
        return Globals.Input_ItemClass
    else
        EngineError("Invalid Spawn type, use Respawn.SetType() before Respawn.Create()")
    end
end

on_tick = function(delta)
    delta = delta or 0.5
    for i=1,#active_spawns do
        local spawn = active_spawns[i]
        if spawn.Alive then
            if spawn.Type == Respawn.Item and GetWidgetLife(spawn.Alive) < 1 then
                reset_resource(spawn.Alive)
            end
        elseif active_spawns[i].IsActive() and active_worldzones[spawn.World] then
            spawn.Clock = spawn.Clock - delta -- * get_timefactor(spawn.World)
            if spawn.Clock <= 0 then
                spawn.Alive = spawn_handle(i)
                if spawn.Callback then
                    spawn.Callback(spawn)
                end
            end
        end
    end
end

reset_resource_index = function(spawn_index)
        local spawn = active_spawns[spawn_index]
        spawn.Alive = nil
        spawn.Clock = GetRandomReal(spawn.Period[1], spawn.Period[2])
end

reset_resource = function(handle)
    local spawn_index = handle_hashmap[handle] or nil
    handle_hashmap[handle] = nil
    if spawn_index ~= nil then
        reset_resource_index(spawn_index)
    end
end

on_item_pickup = function(player, unit, item, item_type)
    reset_resource(item)
end

on_mob_death = function(player, unit)
    reset_resource(unit)
end


spawn_handle = function(spawn_index)
    local spawn = active_spawns[spawn_index]
    -- local target_player = spawn.Owner
    local loc = GetRandomLocInRect(spawn.Region)
    local hdl = nil
    if spawn.Type == Respawn.Unit then
        local target_player = spawn.Owner or HOSTILE_FORCES[GetRandomInt(1, #HOSTILE_FORCES)]
        hdl = CreateUnitAtLoc(target_player, spawn.EntityHandle, loc, 0.0)
    elseif spawn.Type == Respawn.Item then
        hdl = Item.Spawn(nil, loc, spawn.EntityHandle, 1)
    end
    handle_hashmap[hdl] = spawn_index
    return hdl
end