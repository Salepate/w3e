-- TODO: > Check ownership in equipment
-- TODO: > ownership is bugged if another player attempts to pick up the item first (ownership will never be removed)
-- private data
local items = {}
local listeners = Listener.Create()
local owners = {}
local force_remove = {} -- list of unauthorized pickups
local item_owner = {} -- HACK: GetManipulatingUnit() is null for stack event, complicating everything, so this records which unit owns which item
-- private callbacks
local on_item_pickup, on_item_stack, on_tick

Module("Item", {
    SpawnEvent = 1,
    PickUpEvent = 2,
    StackEvent = 3,

    -- register a new database item
    Register = function(itemID --[[string]], itemName --[[string]])
        local itemIDCode = FourCC(itemID)
        items[string.lower(itemName)] = itemIDCode
        items[string.lower(itemID)] = itemIDCode
    end,

    -- listen to pick up events
    ListenEvent = function(callback --[[callback(player, unit, item, item type)]], eventType --[[integer]])
        listeners.listen(callback, eventType)
    end,

    -- get an item type by name (or code)
    GetIdFromName = function(name --[[string]])
        return items[string.lower(name)] or FourCC(name) or nil
    end,

    GetOwner = function(item)
        return owners[item]
    end,

    CanInteract = function(unit, item)
        return item[owner] == nil or item[owner] == GetOwningPlayer(unit)
    end,

    -- spawn an item
    Spawn = function(player --[[player handle]], loc, itemID --[[item type]], itemCount --[[integer]], userData --[[integer]])
        if itemID ~= nil then
            local whichItem = CreateItemLoc(itemID, loc)

            if GetItemType(whichItem) == ITEM_TYPE_CHARGED then
                local limit = math.min(MAX_STACK or 10, (itemCount and tonumber(itemCount)) or 1)
                SetItemCharges(whichItem, limit)
            end

            if player then
                owners[whichItem] = player
            end

            if userData and userData > 0 then
                SetItemUserData(whichItem, userData)
            end

            listeners.invoke(Item.SpawnEvent, player, nil, whichItem, GetItemTypeId(whichItem))
            return whichItem
        else
            return nil
        end
    end,

    -- spawn an item
    Give = function(unit --[[unit handle]], itemID --[[item type]], itemCount --[[integer]])
        if itemID ~= nil then
            local limit = math.min(MAX_STACK or 10, (itemCount and tonumber(itemCount)) or 1)
            local whichItem = UnitAddItemByIdSwapped(itemID, unit)

            if GetItemType(whichItem) == ITEM_TYPE_CHARGED then
                SetItemCharges(whichItem, limit)
            end

            listeners.invoke(Item.SpawnEvent, GetOwningPlayer(unit), unit, whichItem, GetItemTypeId(whichItem))
            return whichItem
        else
            return nil
        end
    end,

    Destroy = function(item --[[item handle]])
        owners[item] = nil
        RemoveItem(item)
    end,

    MarkDestroyed = function(item --[[item handle]])
        owners[item] = nil
    end,

    -- count (sum of charges) items on unit
    Count = function(whichUnit --[[unit handle]], whichItemType --[[unit type]])
        local sum = 0
        for i=0,5 do
            local item = UnitItemInSlot(whichUnit, i)
            if GetItemTypeId(item) == whichItemType then
                if GetItemType(item) == ITEM_TYPE_CHARGED then
                    sum = sum + GetItemCharges(item)
                else
                    sum = sum + 1
                end
            end
        end
        return sum
    end,

    -- spend (and destroy if necessary) n charges of a specific item type on a unit
    Consume = function(whichUnit --[[unit handle]], whichItemType --[[unit type]], count --[[integer]])
        for i=0,5 do
            local item = UnitItemInSlot(whichUnit, i)

            if GetItemTypeId(item) == whichItemType then
                local charges = GetItemCharges(item) or 1
                local canConsume = math.min(count, charges)
                if canConsume == charges then -- item destroyed
                    RemoveItem(item)
                else
                    SetItemCharges(item, charges - canConsume)
                end
                count = count - canConsume
            end
            if count <= 0 then
                return
            end
        end
    end,

    OnStart = function()
        local gg_trg = CreateTrigger()
        TriggerRegisterAnyUnitEventBJ(gg_trg, EVENT_PLAYER_UNIT_PICKUP_ITEM)
        TriggerAddAction(gg_trg, on_item_pickup)
        gg_trg = CreateTrigger()
        TriggerRegisterAnyUnitEventBJ(gg_trg, EVENT_PLAYER_UNIT_STACK_ITEM)
        TriggerAddAction(gg_trg, on_item_stack)

        Clock.Register(on_tick, 0.5)
    end
})

-- private declarations
on_item_pickup = function()
    local unit = GetManipulatingUnit()
    local player = GetOwningPlayer(unit)
    local item = GetManipulatedItem()

    if BlzGetManipulatedItemWasAbsorbed() then -- handled by second callback
        return
    end
    
    if owners[item] and owners[item] ~= player then
        table.insert(force_remove, {unit, item, GetItemLoc(item), owners[item]})
        FloatText.Create(unit, "Item bound to " .. GetPlayerName(owners[item]), 1.5, FloatText.Red, true)
    else
        owners[item] = nil -- remove player ownership
        item_owner[item] = unit -- store unit ownership
        listeners.invoke(Item.PickUpEvent, player, unit, item, GetItemTypeId(item))
    end
end

-- private declarations
on_item_stack = function()
    local unit = GetManipulatingUnit() or item_owner[BlzGetStackingItemTarget()]
    local player = GetOwningPlayer(unit)
    local item = BlzGetStackingItemSource()

    if owners[item] ~= nil and owners[item] ~= player then
        local charges = GetItemCharges(BlzGetStackingItemTarget()) - BlzGetStackingItemTargetPreviousCharges()
        SetItemCharges(BlzGetStackingItemTarget(), BlzGetStackingItemTargetPreviousCharges())
        Item.Spawn(owners[item], GetItemLoc(item), GetItemTypeId(item), charges, GetItemUserData(item))
        FloatText.Create(unit, "Item bound to " .. GetPlayerName(owners[item]), 1.5, FloatText.Red, true)
    else
        listeners.invoke(Item.StackEvent, player, unit, item, GetItemTypeId(item))
    end
    Item.MarkDestroyed(item)
end

on_tick = function()
    for i=#force_remove,1,-1 do
        local pickup = force_remove[i]
        UnitDropItemPointLoc(pickup[1], pickup[2], GetUnitLoc(pickup[1]))
        SetItemPositionLoc(pickup[2], pickup[3])
        table.remove(force_remove, i)
    end
end