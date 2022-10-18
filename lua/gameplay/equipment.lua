-- data
local player_equipments = {}
local equipment_db = {}
-- locals funcs/events
local on_tick, on_use_item
local create_triggers, destroy_triggers, update_position
local player_triggers = {}

local effects = {}

-- module
Module("Equipment", {
    EffectDamage = 1,
    EffectArmor = 2,
    EffectAttackSpeed = 3,

    Weapon = 1,
    Chest = 2,

    AddDamage = function(base, dices, sides)
        table.insert(effects, { Type = Equipment.EffectDamage, Value = {base or 0, dices or 0, sides or 0}})
    end,
    
    AddAttackSpeed = function(multiplier)
        table.insert(effects, { Type = Equipment.EffectAttackSpeed, Value = multiplier})
    end,

    AddArmor = function(armor_value)
        table.insert(effects, { Type = Equipment.EffectArmor, Value = armor_value })
    end,

    Register = function(gear_type)
        local item_class = Globals.Input_ItemClass
        if equipment_db[item_class] ~= nil then
            EngineError("Duplicate Equipment detected:" .. tostring(item_class))
        else
            equipment_db[item_class] =
            {
                Type = gear_type,
                Effects = effects
            }

            effects = {}
        end
    end,

    RecomputeStats = function(player)
        local survivor = GetPlayerSurvivor(player)
        local equip = player_equipments[player]

        local atk_spd_multiplier = 1.00
        -- simulate base stats using Starter module
        local base_unit = Start.GetUnitHandleByClass(GetUnitTypeId(survivor))
        SetHeroLevel(base_unit, GetHeroLevel(survivor), false)
        local base_damage = BlzGetUnitBaseDamage(base_unit, 0)
        local base_def = BlzGetUnitArmor(base_unit)
        local dice_number = BlzGetUnitDiceNumber(base_unit, 0)
        local dice_sides = BlzGetUnitDiceSides(base_unit, 0)
        local atk_cooldown = BlzGetUnitAttackCooldown(base_unit, 0)
        SetHeroLevel(base_unit, 0, false)

        for i=0,3 do 
            local item_class = GetItemTypeId(UnitItemInSlot(equip, i))
            local equip_data = equipment_db[item_class]
            
            if item_class ~= ITEM_EMPTY_DUMMY and equip_data ~= nil then
                for j=1,#equip_data.Effects do
                    local effect = equip_data.Effects[j]
                    if effect.Type == Equipment.EffectDamage then
                        base_damage = base_damage + effect.Value[1]
                        dice_number = dice_number + effect.Value[2]
                        dice_sides = dice_sides + effect.Value[3]
                    elseif effect.Type == Equipment.EffectArmor then
                        base_def = base_def + effect.Value
                    elseif effect.Type == Equipment.EffectAttackSpeed then
                        atk_spd_multiplier = atk_spd_multiplier + effect.Value
                    end
                end
            end
        end
        BlzSetUnitBaseDamage(survivor, base_damage, 0)
        BlzSetUnitDiceNumber(survivor, dice_number, 0)
        BlzSetUnitDiceSides(survivor, dice_sides, 0)
        BlzSetUnitArmor(survivor, base_def)
        BlzSetUnitAttackCooldown(survivor, atk_cooldown / atk_spd_multiplier, 0)
    end,

    TryEquip = function(player, item)
        item_class = GetItemTypeId(item)
        local equipment_data = equipment_db[item_class]
        local equip_unit = player_equipments[player]
        local prev_item = UnitItemInSlot(equip_unit, equipment_data.Type - 1)
        local survivor = GetPlayerSurvivor(player)

        if prev_item ~= nil then
            if GetItemTypeId(prev_item) ~= ITEM_EMPTY_DUMMY then
                UnitRemoveItem(equip_unit, prev_item)
            else
                RemoveItem(prev_item)
            end
        end

        RemoveItem(item)
        UnitAddItemToSlotById(equip_unit, item_class, equipment_data.Type - 1)

        if prev_item ~= nil then
            UnitAddItem(survivor, prev_item)
        end

        Equipment.RecomputeStats(player)
    end,

    Create = function(player --[[player handle]])
        if player_equipments[player] == nil then
            local unit = CreateUnitAtLoc(player, UNIT_EQUIPMENT, GetUnitLoc(GetPlayerSurvivor(player)), 0.0)
            SetHeroLevel(unit, 20, false)
            SuspendHeroXP(unit, true)
            player_equipments[player] = unit
            for i=0,3 do 
                UnitAddItemToSlotById(unit, ITEM_EMPTY_DUMMY, i)
            end
            create_triggers(player)
        end
    end,

    Destroy = function(player --[[player handle]])
        if player_equipments[player] ~= nil then
            RemoveUnit(player_equipments[player])
            player_equipments[player] = nil
            destroy_triggers(player)
        end
    end,

    OnStart = function()
        Clock.Register(on_tick, 2.0)

        local gg_trg = CreateTrigger()
        TriggerRegisterAnyUnitEventBJ(gg_trg, EVENT_PLAYER_UNIT_USE_ITEM)
        TriggerAddAction(gg_trg, on_use_item)
    end
})

on_use_item = function()
    local item = GetManipulatedItem()
    local p = GetOwningPlayer(GetManipulatingUnit())
    local itype = GetItemTypeId(item)
    if equipment_db[itype] ~= nil then
        Equipment.TryEquip(p, item)
    end
end

create_triggers = function(player)
    destroy_triggers(player)

    local gg_trg = CreateTrigger()
    TriggerRegisterPlayerSelectionEventBJ(gg_trg, player, true)
    TriggerAddAction(gg_trg, function()
        local unit = GetTriggerUnit()
        local unit_type = GetUnitTypeId(unit)
        if unit_type == UNIT_EQUIPMENT and GetOwningPlayer(unit) == GetTriggerPlayer() then
            update_position(player)
        end
    end)
end

destroy_triggers = function(player)
    if player_triggers[player] ~= nil then
        DestroyTrigger(player_triggers[player])
        player_triggers[player] = nil
    end
end

on_tick = function(dt)
    for k in pairs(player_equipments) do
        update_position(k)
    end
end

update_position = function(player)
    SetUnitPositionLoc(player_equipments[player], GetUnitLoc(GetPlayerSurvivor(player)))
end