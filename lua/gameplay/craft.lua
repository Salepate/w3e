-- private data
local upgrade_map = {}
-- private func/events
local on_craft_processed, on_craft_requested

-- module
Module("Craft", {
    GetIndex = function(whichunittype)
        local size = #udg_Craft_IngredientCount
        for i=1,size do
            if udg_Craft_UnitDummy[i] == whichunittype then
                return i
            end
        end
        return 0
    end,

    CraftAbility = function(unit, craft_index, resultcb)
        local p = GetOwningPlayer(unit)
        local trg_cast = CreateTrigger()
        UnitAddAbility(unit, udg_Craft_AbilityDummy[craft_index])

        TriggerRegisterAnyUnitEventBJ(trg_cast, EVENT_PLAYER_UNIT_SPELL_CAST)
        TriggerAddAction(trg_cast, function()
            if GetSpellAbilityUnit() ~= unit then
                return
            end

            if GetOwningPlayer(GetSpellAbilityUnit()) ~= p then
                return
            end
            if GetSpellAbilityId(GetSpellAbility()) ~= udg_Craft_AbilityDummy[craft_index] then
                return
            end

            local craft_success = Craft.HasIngredients(unit, craft_index)
            if not craft_success then
                FloatText.Create(unit, "Missing Ingredients!", 1.5, FloatText.Red)
            else
                Craft.ConsumeIngredients(unit, craft_index)
                DestroyTrigger(trg_cast)
                Clock.DelayedCallback(function() UnitRemoveAbility(unit, udg_Craft_AbilityDummy[craft_index]) end, 2.0)
            end
            resultcb(craft_success)
        end)
    end,

    GetIndexByUnitConstruct = function(whichunittype)
        local size = #udg_Craft_IngredientCount
        for i=1,size do
            if udg_Craft_UnitConstruct[i] == whichunittype then
                return i
            end
        end
        return 0
    end,

    HasProperty = function(craft_index, property_set)
        return (Globals.Craft_Properties[craft_index] & property_set) == property_set
    end,

    HasIngredients = function(survivor, craft_index)
        local ingredientCount = udg_Craft_IngredientCount[craft_index]
        if ingredientCount >= 1 and Item.Count(survivor, udg_Craft_IngredientType01[craft_index]) < udg_Craft_IngredientValue01[craft_index] then
            return false
        end
        if ingredientCount >= 2 and Item.Count(survivor, udg_Craft_IngredientType02[craft_index]) < udg_Craft_IngredientValue02[craft_index] then
            return false
        end
        if ingredientCount >= 3 and Item.Count(survivor, udg_Craft_IngredientType03[craft_index]) < udg_Craft_IngredientValue03[craft_index] then
            return false
        end
        return true
    end,

    RefundIngredients = function(survivor, craft_index, at)
        local ingredientCount = udg_Craft_IngredientCount[craft_index]
        if ingredientCount >= 1 then
            Item.Spawn(nil, at, udg_Craft_IngredientType01[craft_index], udg_Craft_IngredientValue01[craft_index])
        end
        if ingredientCount >= 2 then
            Item.Spawn(nil, at, udg_Craft_IngredientType02[craft_index], udg_Craft_IngredientValue02[craft_index])
        end
        if ingredientCount >= 3 then
            Item.Spawn(nil, at, udg_Craft_IngredientType03[craft_index], udg_Craft_IngredientValue03[craft_index])
        end
    end,

    ConsumeIngredients = function(survivor, craft_index)
        local ingredientCount = udg_Craft_IngredientCount[craft_index]
        if ingredientCount >= 1 then
            Item.Consume(survivor, udg_Craft_IngredientType01[craft_index], udg_Craft_IngredientValue01[craft_index])
        end
        if ingredientCount >= 2 then
            Item.Consume(survivor, udg_Craft_IngredientType02[craft_index], udg_Craft_IngredientValue02[craft_index])
        end
        if ingredientCount >= 3 then
            Item.Consume(survivor, udg_Craft_IngredientType03[craft_index], udg_Craft_IngredientValue03[craft_index])
        end
    end,
    
    OnStart = function()
        local trg_craft = CreateTrigger()
        local trg_craft_complete = CreateTrigger()
        local trg_upgrade = CreateTrigger()
        local trg_upgrade_cancel = CreateTrigger()
        local trg_upgrade_complete = CreateTrigger()
        TriggerRegisterAnyUnitEventBJ(trg_craft, EVENT_PLAYER_UNIT_TRAIN_START)
        TriggerAddAction(trg_craft, on_craft_requested)
        TriggerRegisterAnyUnitEventBJ(trg_craft_complete, EVENT_PLAYER_UNIT_TRAIN_FINISH)
        TriggerAddAction(trg_craft_complete, on_craft_processed)
        TriggerRegisterAnyUnitEventBJ(trg_upgrade, EVENT_PLAYER_UNIT_UPGRADE_START)
        TriggerAddAction(trg_upgrade, on_upgrade_requested)
        TriggerRegisterAnyUnitEventBJ(trg_upgrade_cancel, EVENT_PLAYER_UNIT_UPGRADE_CANCEL)
        TriggerAddAction(trg_upgrade_cancel, on_upgrade_cancelled)
        TriggerRegisterAnyUnitEventBJ(trg_upgrade_complete, EVENT_PLAYER_UNIT_UPGRADE_FINISH)
        TriggerAddAction(trg_upgrade_complete, on_upgrade_complete)
    end,
})


-- private implems
on_upgrade_requested = function()
    local station_unit = GetTriggerUnit()
    local upgrade_type = GetUnitTypeId(station_unit)
    local p = GetOwningPlayer(station_unit)
    local survivor = GetPlayerSurvivor(p)
    local survivor_pt = GetUnitLoc(survivor)
    local station_pt = GetUnitLoc(station_unit)

    local validate_train = false
    local craft_idx = -1

    if DistanceBetweenPoints(survivor_pt, station_pt) <= BASE_CRAFT_DISTANCE then
        craft_index = Craft.GetIndexByUnitConstruct(upgrade_type)
        if craft_index < 1 then
            EngineError("Unknown Recipe", p)
        else
            if Craft.HasIngredients(survivor, craft_index) then
                validate_train = true
            else
                FloatText.Create(survivor, GameText.CRAFT_FLOAT_NOINGREDIENTS, 1.5, FloatText.Red, true)
            end
        end
    else
        FloatText.Create(survivor, GameText.CRAFT_FLOAT_STATIONDISTANCE, 1.5, FloatText.Red, true)
    end

    if not validate_train then
        IssueImmediateOrderById(station_unit, ORDER_CANCEL)
    else
        upgrade_map[station_unit] = upgrade_type
        Craft.ConsumeIngredients(survivor, craft_index)
        UnitRemoveAbility(station_unit, ABILITY_RALLY)
    end
end

on_upgrade_cancelled = function()
    local unit = GetTriggerUnit()
    local owner = GetOwningPlayer(unit)
    local survivor = GetPlayerSurvivor(owner)
    local craft_idx = Craft.GetIndexByUnitConstruct(upgrade_map[unit])
    Craft.RefundIngredients(survivor, craft_idx, GetUnitLoc(unit))
    UnitRemoveAbility(unit, ABILITY_RALLY)
end

on_upgrade_complete = function()
    upgrade_map[GetTriggerUnit()] = nil
end

on_craft_requested = function() -- Callback: Unit Starts training
    local trained_unit_type = GetTrainedUnitType()
    local station_unit = GetTriggerUnit()
    local p = GetOwningPlayer(station_unit)
    local survivor = GetPlayerSurvivor(p)
    local survivor_pt = GetUnitLoc(survivor)
    local station_pt = GetUnitLoc(station_unit)

    local validate_train = false

    if DistanceBetweenPoints(survivor_pt, station_pt) <= BASE_CRAFT_DISTANCE then
        local craft_index = Craft.GetIndex(trained_unit_type)
        if craft_index < 1 then
            EngineError("Unknown Recipe", p)
        else
            if Craft.HasIngredients(survivor, craft_index) then
                validate_train = true
            else
                FloatText.Create(survivor, GameText.CRAFT_FLOAT_NOINGREDIENTS, 1.5, FloatText.Red, true)
            end
        end
    else
        FloatText.Create(survivor, GameText.CRAFT_FLOAT_STATIONDISTANCE, 1.5, FloatText.Red, true)
    end

    if not validate_train then
        IssueImmediateOrderById(station_unit, ORDER_CANCEL)
    end
end

on_craft_processed = function()
    local trained_unit_type = GetTrainedUnitType()
    local station_unit = GetTriggerUnit()
    local p = GetOwningPlayer(station_unit)
    local survivor = GetPlayerSurvivor(p)
    local craft_index = Craft.GetIndex(trained_unit_type)

    if craft_index < 1 then
        EngineError("Unknown Recipe")
    else
        if DistanceBetweenPoints(GetUnitLoc(survivor), GetUnitLoc(station_unit)) > BASE_CRAFT_DISTANCE then
            FloatText.Create(survivor, GameText.CRAFT_FLOAT_STATIONDISTANCE, 1.5, FloatText.Red, true)
        elseif Craft.HasIngredients(survivor, craft_index) then
            Craft.ConsumeIngredients(survivor, craft_index)
            local trainedUnit_loc = GetUnitLoc(GetTrainedUnit())
            local whichItem =  Item.Spawn(p, trainedUnit_loc, udg_Craft_ItemResult[craft_index], udg_Craft_ItemCount[craft_index] or 1)
        else
            FloatText.Create(survivor, GameText.CRAFT_FLOAT_NOINGREDIENTS, 1.5, FloatText.Red, true)
        end
    end
    RemoveUnit(GetTrainedUnit())
end