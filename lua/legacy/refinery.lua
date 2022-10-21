local database = {}

local create_entry = function()
    return
    {
        Production = {}
    }
end

function AddProductionLine(inputItem, inputCount, outputItem, outputCount, time)
    local entry = database[udg_Workshop_Unit]
    if entry == nil then
        EngineError("Unknown Refinery entry " .. tostring(udg_Workshop_Unit))
    else
        table.insert(entry.Production, 
        {
            Input = {inputItem, inputCount},
            Output = {outputItem, outputCount},
            Time = time
        })
    end
end

function RegisterRefinery()
    local entry = create_entry()
    database[udg_Workshop_Unit] = entry
    AddProductionLine(udg_Workshop_InputItem, udg_Workshop_InputValue, udg_Workshop_OutputItem, udg_Workshop_OutputValue, udg_Workshop_ProductionTime)
end

RegisterSystem(function()
    local active_refineries = {}

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

    local ProcessInputItem = function(unit, db, item, itemtype)
        for i=1,#db.Production do
            local prod = db.Production[i]

            if prod.Input[1] == itemtype then
                return
            end
        end

        FloatText.Create(unit, "Invalid Input", 1.5, FloatText.Red)
        UnitRemoveItemSwapped(item, unit) -- no preemptive returns means item should be discarded
    end

    local OnRefineryConstructed = function(player, unit, workshop_entity)
        workshop_entity.IsProducing = false
        workshop_entity.ProductionClock = 0
        table.insert(active_refineries, unit)
    end

    local reset_demand = function(workshop)
        workshop.demand = 0
    end

    local OnRefineryTick = function()
        Workshop.ProcessAllWorkshops(reset_demand)
        for i=1,#active_refineries do
            local unit = active_refineries[i]
            local ws = Workshop.GetWorkshopInfo(GetOwningPlayer(unit))
            local entity = Workshop.GetWorkshopUnitInfo(unit)
            local db = database[GetUnitTypeId(unit)]
            local demand = 0

            if ws.demand + 1 <= (ws.supply or 0) then
                if entity.IsProducing then
                    demand = 1
                    entity.ProductionClock = entity.ProductionClock - 1
                    if entity.ProductionClock <= 0 then
                        entity.IsProducing = false
                        local prod = db.Production[entity.Production]
                        for i=1,#prod.Output - 1,2 do
                            Item.Spawn(nil, GetUnitLoc(unit), prod.Output[i], prod.Output[i+1])
                        end
                    end
                end
    
                if not entity.IsProducing then
                    local prodIndex = CanProduce(unit, db)
                    if prodIndex ~= 0 then
                        demand = 1
                        local prod = db.Production[prodIndex]
                        entity.IsProducing = true
                        entity.ProductionClock = prod.Time
                        entity.Production = prodIndex
                        for i=1,#prod.Input - 1,2 do
                            Item.Consume(unit, prod.Input[i], prod.Input[i+1])
                        end
                    end
                end
                ws.demand = ws.demand + demand
                entity.active = entity.active + (entity.IsProducing and 1 or 0)
            end
        end
    end

    local OnItemPickup = function(player, unit, item, itemtype)
        local db_data = database[GetUnitTypeId(unit)]
        if db_data ~= nil then
            ProcessInputItem(unit, db_data, item, itemtype)
        end
    end

    Workshop.SetWorkshopTable(database, OnRefineryConstructed)
    Workshop.AddTickCallback(OnRefineryTick)
    Item.ListenEvent(OnItemPickup, Item.PickUpEvent)
end)