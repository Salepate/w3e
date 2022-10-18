-- data
local backpacks = {}
-- local funcs
local on_tick, update_position
-- legacy

function InitBackpack()
    local item_backpack = FourCC("I00D")
    local unit_backpack = FourCC("H009")
    local pack_ability = FourCC("A00A")
    local unpack_ability = FourCC("A00C")
    local unit_backpack_dummy = FourCC("h00A")
    local visible = {}

    local range_triggers = {}
    local range_regions = {}

    -- OnStart = function()
        Clock.Register(on_tick, 2.0)
    -- end


    -- local castPack = function(player, whichUnit, ability, ability_type)
    --     local backpack = backpacks[player]

    --     if backpack == nil then
    --         return
    --     end

    --     if ability_type == pack_ability then
    --         HideBackpack(player)
    --         visible[player] = false
    --     elseif ability_type == unpack_ability then
    --         ShowBackpack(player)
    --         visible[player] = true
    --     end
    -- end

    local onUnitLeaveRange = function()
        local unit = GetTriggerUnit()
        local player = GetOwningPlayer(unit)
        local survivor = GetPlayerSurvivor(player)
        local region = GetTriggeringRegion()

        if unit == survivor and region == range_regions[player] then
            HideBackpack(player)
        end
    end

    local onItemSpawned = function(whichPlayer, unit, whichItem, itemtype)
        if itemtype == item_backpack then
            if whichPlayer == nil then
                EngineError("Cannot assign backpack, player is missing")
            else
                SetPlayerUnitAvailableBJ(unit_backpack_dummy, false, whichPlayer)
                SpawnPlayerBackpack(whichPlayer)
            end
            RemoveItem(whichItem)
        end
    end

    function HasBackpack(player)
        return backpacks[player] ~= nil
    end

    function ShowBackpack(player)
        if visible[player] ~= false then
            return
        end
        local backpack = backpacks[player]
        SetUnitScale(backpack, 1.0, 1.0, 1.0)
        SetUnitPositionLoc(backpack, GetUnitLoc(GetPlayerSurvivor(player)))
        -- UnitAddAbility(backpack, pack_ability)
        -- UnitRemoveAbility(backpack, unpack_ability)
        CreateBackpackRangeTrigger(player)
        visible[player] = true
    end

    function HideBackpack(player)
        if visible[player] ~= true then
            return
        end
        local backpack = backpacks[player]
        SelectUnitForPlayerSingle(GetPlayerSurvivor(player), player)
        SetUnitScale(backpack, 0.0, 0.0, 0.0)
        -- UnitRemoveAbility(backpack, pack_ability)
        -- UnitAddAbility(backpack, unpack_ability)
        ClearBackpackRangeTrigger(player)
        visible[player] = false
    end

    function SpawnPlayerBackpack(whichPlayer)
        if backpacks[whichPlayer] == nil then
            backpacks[whichPlayer] = CreateUnitAtLoc(whichPlayer, unit_backpack, GetUnitLoc(GetPlayerSurvivor(whichPlayer)), 0.0)
            SetHeroLevel(backpacks[whichPlayer], 20, false)
            SuspendHeroXP(backpacks[whichPlayer], true)
            visible[whichPlayer] = true
            CreatePlayerTriggers(whichPlayer)
            HideBackpack(whichPlayer, backpacks[whichPlayer])
        end
    end

    function CreatePlayerTriggers(whichPlayer)
        local gg_trg = CreateTrigger()
        TriggerRegisterPlayerSelectionEventBJ(gg_trg, whichPlayer, true)
        TriggerAddAction(gg_trg, function()
            local unit_type = GetUnitTypeId(GetTriggerUnit())
            if unit_type == unit_backpack then
                if not visible[whichPlayer] then
                    SetUnitPositionLoc(GetTriggerUnit(), GetUnitLoc(GetPlayerSurvivor(whichPlayer)))
                end
            end
        end)
    end

    function CreateBackpackRangeTrigger(player)
        local backpack = backpacks[player]
        local gg_trg = CreateTrigger()
        range_triggers[player] = gg_trg
        local reg = CreateRegion()
        RegionAddRect(reg, RectFromCenterSizeBJ(GetUnitLoc(backpack), 300, 300))
        range_regions[player] = reg
        TriggerRegisterLeaveRegion(gg_trg, range_regions[player], nil)
        TriggerAddAction(gg_trg, onUnitLeaveRange)
    end

    function ClearBackpackRangeTrigger(player)
        local region = range_regions[player]

        if range_triggers[player] ~= nil then
            DestroyTrigger(range_triggers[player])
        end

        if region ~= nil then
            RemoveRegion(region)
        end

        range_triggers[player] = nil
        range_regions[player] = nil
    end

    --  RegisterCastListener(castPack, false)
    Item.ListenEvent(onItemSpawned, Item.SpawnEvent)
end

on_tick = function(dt)
    for k in pairs(backpacks) do
        update_position(k)
    end
end

update_position = function(player)
    SetUnitPositionLoc(backpacks[player], GetUnitLoc(GetPlayerSurvivor(player)))
end