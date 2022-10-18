-- data
local expiration_buff
local learn_map = {}
local disable_map = {}
local is_aggressive = false
-- funcs/callbacks
local on_unit_learn_skill

-- Module
Module("Cast",
{
    -- Use Globals : Input_AbilityClass - ability to bind to (the one in skill tree)
    SetSpellbook = function(spellbook_ability --[[fourcceable string]])
        local base_ability = Globals.Input_AbilityClass
        spellbook_ability = FourCC(spellbook_ability)
        learn_map[base_ability] = learn_map[base_ability] or {}
        table.insert(learn_map[base_ability], spellbook_ability)
        table.insert(disable_map, spellbook_ability)
    end,

    Aggro = function(state)
        is_aggressive = (state and true) or false
    end,

    -- Use Globals : Input_AbilityClass - ability to cast
    NoTarget = function(level --[[ number or nil to match spell cast ability]])
        local unit_class = (is_aggressive and UNIT_DUMMY_CASTER_AGGRO) or UNIT_DUMMY_CASTER
        local unit = GetSpellAbilityUnit()
        local owner = GetOwningPlayer(unit)
        local caster = CreateUnit(owner, unit_class, GetUnitX(unit), GetUnitY(unit), GetUnitFacing(unit))
        if level == nil then
            level = GetUnitAbilityLevel(unit, GetSpellAbilityId())
        end
        UnitAddAbility(caster, Globals.Input_AbilityClass)
        SetUnitAbilityLevel(caster, Globals.Input_AbilityClass, level)
        UnitApplyTimedLife(caster, expiration_buff, 5.0)
        rawset(_G,"udg_Cast_Caster", caster)
        Cast.Aggro(false)
    end,

    -- Use Globals : Input_AbilityClass - ability to cast
    TargetToDummyTarget = function(level --[[ number or nil to match spell cast ability]])
        local unit_class = (is_aggressive and UNIT_DUMMY_CASTER_AGGRO) or UNIT_DUMMY_CASTER
        local unit = GetSpellAbilityUnit()
        local owner = GetOwningPlayer(unit)
        local caster = CreateUnit(owner, unit_class, GetUnitX(unit), GetUnitY(unit), GetUnitFacing(unit))
        if level == nil then
            level = GetUnitAbilityLevel(unit, GetSpellAbilityId())
        end
        UnitAddAbility(caster, Globals.Input_AbilityClass)
        SetUnitAbilityLevel(caster, Globals.Input_AbilityClass, level)
        UnitApplyTimedLife(caster, expiration_buff, 5.0)

        -- target
        local target = CreateUnitAtLoc(HOSTILE_FORCES[1], UNIT_DUMMY_TARGET, GetUnitLoc(GetSpellTargetUnit()), 0.0)
        UnitApplyTimedLife(target, expiration_buff, 5.0)
        rawset(_G,"udg_Cast_Caster", caster)
        rawset(_G, "udg_Cast_Target", target)
        Cast.Aggro(false)
    end,

    -- Use Globals : Input_AbilityClass - ability to cast
    PointToTarget = function(level --[[ number or nil to match spell cast ability]])
        local unit_class = (is_aggressive and UNIT_DUMMY_CASTER_AGGRO) or UNIT_DUMMY_CASTER
        local unit = GetSpellAbilityUnit()
        local owner = GetOwningPlayer(unit)
        local caster = CreateUnit(owner, unit_class, GetUnitX(unit), GetUnitY(unit), GetUnitFacing(unit))
        if level == nil then
            level = GetUnitAbilityLevel(unit, GetSpellAbilityId())
        end
        UnitAddAbility(caster, Globals.Input_AbilityClass)
        SetUnitAbilityLevel(caster, Globals.Input_AbilityClass, level)
        UnitApplyTimedLife(caster, expiration_buff, 5.0)

        -- target
        local target = CreateUnitAtLoc(HOSTILE_FORCES[1], UNIT_DUMMY_TARGET, GetSpellTargetLoc(), 0.0)
        UnitApplyTimedLife(target, expiration_buff, 5.0)
        rawset(_G,"udg_Cast_Caster", caster)
        rawset(_G, "udg_Cast_Target", target)
        Cast.Aggro(false)
    end,

    OnStart = function()
        expiration_buff = FourCC("BTLF")
        local gg_trg = CreateTrigger()
        TriggerRegisterAnyUnitEventBJ(gg_trg, EVENT_PLAYER_HERO_SKILL)
        TriggerAddAction(gg_trg, on_unit_learn_skill)

        -- disable abilities
        for i=1,#W3E.Players do
            for j=1,#disable_map do
                SetPlayerAbilityAvailable(W3E.Players[i], disable_map[j], false)
            end
        end
    end
})

-- implems
on_unit_learn_skill = function()
    local unit = GetTriggerUnit()
    local ability = GetLearnedSkill()
    if GetLearnedSkillLevel() > 1 then
        return
    end
    if learn_map[ability] then
        UnitRemoveAbility(unit, ability)
        for i=1,#learn_map[ability] do
            UnitAddAbility(unit, learn_map[ability][i])
        end
    end
end