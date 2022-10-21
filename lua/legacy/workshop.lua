local sub_systems = {}

Workshop = (function() 
        local unit_map = {}
        local unitSpawnListeners = {}
        local unitTickListeners = {}
        local workshops = {} -- player industries
        local active_ws = {} -- array
        local entities = {} -- array

        local get_player_workshop = function(player)
            if workshops[player] == nil then
                workshops[player] = { units = {} }

                table.insert(active_ws, workshops[player])
            end

            return workshops[player]
        end

        local create_workshop_entity = function(player, unit)
            local ws = get_player_workshop(player)
            local obj = { unit = unit, active = 0, working = false}
            ws.units[unit] = obj
            table.insert(entities, obj)
            return obj
        end


        return 
        {
            GetWorkshopInfo = function(player)
                return get_player_workshop(player)
            end,

            GetWorkshopUnitInfo = function(unit)
                local ws = get_player_workshop(GetOwningPlayer(unit))
                return ws.units[unit]
            end,

            ProcessAllWorkshops = function(processor_callback)
                for i=1,#active_ws do
                    processor_callback(active_ws[i])
                end
            end,
            SetWorkshopTable = function(db, callback)
                for k in pairs(db) do
                    if unit_map[k] == nil then
                        unit_map[k] = callback
                    else
                        EngineError("Duplicate unit detected in workshop!")
                    end
                end
            end,

            AddTickCallback = function(callback)
                table.insert(unitTickListeners, callback)
            end,

            SetUnitConstructed = function(unit)
                local spawnListener = unit_map[GetUnitTypeId(unit)]
                if spawnListener ~= nil then
                    local player = GetOwningPlayer(unit)
                    spawnListener(player, unit, create_workshop_entity(player,unit))
                end
            end,

            OnTick = function()
                for i=1,#unitTickListeners do
                    unitTickListeners[i]()
                end

                for i=1,#entities do
                    local was_working = entities[i].working
                    local is_working = entities[i].active > 0
        
                    if was_working ~= is_working then
                        entities[i].working = is_working
                        local anim = "idle"                
                        if is_working then
                            anim = "work"
                        end
                        SetUnitAnimation(entities[i].unit, anim)
                    end
        
                    entities[i].active = 0
                end
            end,
        }
    end)()

function RegisterSystem(init_callback)
    table.insert( sub_systems, init_callback)
end


function InitWorkshop()
    for i=1,#sub_systems do
        sub_systems[i]()
    end

    local onUnitConstructed = function()
        local unit = GetConstructedStructure()
        Workshop.SetUnitConstructed(unit)
    end

    local gg_trg = CreateTrigger()
    TriggerRegisterAnyUnitEventBJ(gg_trg, EVENT_PLAYER_UNIT_CONSTRUCT_FINISH)
    TriggerAddAction(gg_trg, onUnitConstructed)

    Clock.Register(Workshop.OnTick, 1.0)
end