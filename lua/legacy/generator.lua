local database = {}

local create_entry = function()
    return
    {
        Production = {}
    }
end

local AddGeneratorLine = function(inputItem, inputCount, outputValue, time)
    local entry = database[udg_Workshop_Unit]
    if entry == nil then
        EngineError("Unknown Generator entry " .. tostring(udg_Workshop_Unit))
    else
        table.insert(entry.Production, 
        {
            Input = {inputItem, inputCount},
            Output = outputValue,
            Time = time
        })
    end
end

function RegisterGenerator()
    local entry = create_entry()
    database[udg_Workshop_Unit] = entry
    AddGeneratorLine(udg_Workshop_InputItem, udg_Workshop_InputValue, udg_Workshop_OutputValue, udg_Workshop_ProductionTime)
end

    
RegisterSystem(function()
    local active_generators = {}

    local reset_supply = function(workshop)
        workshop.supply = 0
        workshop.demand = workshop.demand or 0
    end

    local ProcessInputItem = function(unit, db, item, itemtype)
        for i=1,#db.Production do
            local prod = db.Production[i]

            if prod.Input[1] == itemtype then
                return
            end
        end

        UnitRemoveItemSwapped(item, unit) -- no preemptive returns means item should be discarded
    end

    local CanProduce = function(unit, db)
        local production_line = 0
        for i=1,#db.Production do
            local prod = db.Production[i]
            if Item.Count(unit, prod.Input[1]) >= prod.Input[2] then
                production_line = i
                break
            end
        end
        return production_line
    end

    local OnItemPickup = function(player, unit, item, itemtype)
        local db_data = database[GetUnitTypeId(unit)]
        if db_data ~= nil then
            ProcessInputItem(unit, db_data, item, itemtype)
        end
    end


    local OnTick = function()
        Workshop.ProcessAllWorkshops(reset_supply)

        for i=1,#active_generators do
            local unit = active_generators[i]
            local ws = Workshop.GetWorkshopInfo(GetOwningPlayer(unit))
            local entity = Workshop.GetWorkshopUnitInfo(unit)
            local energy = GetUnitState(unit, UNIT_STATE_MANA)
            local max = GetUnitState(unit, UNIT_STATE_MAX_MANA)
            local db = database[GetUnitTypeId(unit)]
            -- only look first prod line for gen
            local prod = db.Production[1]
            if max - energy >= prod.Output or energy < 0.5 then
                if CanProduce(unit, db) > 0 then
                    Item.Consume(unit, prod.Input[1], prod.Input[2])
                    energy = math.min(max, energy + prod.Output)
                end
            end

            if energy >= 1 then
                if ws.demand > 0 then
                    local consumption = math.min(ws.demand, energy)
                    energy = energy - consumption
                end
                ws.supply = ws.supply + prod.Output --TODO: constraint added supply with an other var
            end

            SetUnitState(unit, UNIT_STATE_MANA, math.min(max, energy))
        end
    end

    local OnGeneratorConstructed = function(player, unit, entity)
        table.insert(active_generators, unit)
    end

    Workshop.SetWorkshopTable(database, OnGeneratorConstructed)
    Workshop.AddTickCallback(OnTick)
    Item.ListenEvent(OnItemPickup, Item.PickUpEvent)
end)