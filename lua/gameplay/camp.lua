-- settings
local INITIAL_RANGE = 500.0
local EMPTY_VFX = ""
local BOUNDARY_VFX = "Abilities\\Spells\\Human\\SunderingBlades\\SunderingBlades.mdl"
local ANGLE_DIVS = 24
local DEFAULT_BUILD_DISTANCE = 100.0
local default_build_dist_squared = DEFAULT_BUILD_DISTANCE * DEFAULT_BUILD_DISTANCE
-- local data
local active_camps = {}
local active_radius = {}
local angle_cache = {}
local callback_cache = {}
local request_count = {}
local build_dist_squared = {}
local build_dist = {}
-- private events/funcs
local   on_construct_complete, on_construct_start, on_select_unit, on_unit_dead,
        get_player_callback, get_range, convert_property, get_build_distance
    

TEST_COLOR = {80, 255, 80}
-- module
Module("Camp",
{
    RangeConstruction = 1,
    RangeCraft = 2,

    -- Remove all structures from a player camp
    Terminate = function(player --[[player handle]], message --[[ string ]])
        if not active_camps[player] then
            return
        end
        
        message = message or "Camp destroyed!"
        FloatText.Create(GetPlayerSurvivor(player), message, 4.0, FloatText.Red)
        
        local camp = active_camps[player]
        active_camps[player] = nil
        local structs = camp.Structures
    
        for i=1,#structs do
            local craft_index = Craft.GetIndexByUnitConstruct(GetUnitTypeId(structs[i]))
            if craft_index > 0 and GetUnitStatePercent(structs[i], UNIT_STATE_LIFE, UNIT_STATE_MAX_LIFE) >= 99.00 then
                local loc = GetUnitLoc(structs[i])
                RemoveUnit(structs[i])
                Item.Spawn(player, loc, Globals.Craft_ItemResult[craft_index], 1)
            else
                KillUnit(structs[i])
            end
        end


        if IsUnitAliveBJ(camp.Camp) then
            KillUnit(camp.Camp)
        end
    end,

    HideRadius = function(player)
        for i=1,#active_radius[player] do
            DestroyEffect(active_radius[player][i])
        end
        active_radius[player] = nil
    end,

    ShowRadius = function(unit, range_bitfield)
        local player = GetOwningPlayer(unit)

        if active_radius[player] then
            Camp.HideRadius(player)
        end

        request_count[player] = request_count[player] or 0
        request_count[player] = request_count[player] + 1

        
        local build_dist = get_build_distance(GetUnitTypeId(unit))

        local vfxList = {}
        local loc = GetUnitLoc(unit)
        local vfx = BOUNDARY_VFX 

        if GetLocalPlayer() ~= player then
            vfx = EMPTY_VFX
        end

        for i=1,#angle_cache do
            local angle = angle_cache[i]

            if (range_bitfield & Camp.RangeConstruction) ~= 0 then
                local x = (build_dist+BUILD_DISTANCE_VISUAL_MARGIN) * angle[1]
                local y = (build_dist+BUILD_DISTANCE_VISUAL_MARGIN) * angle[2]
                local effect = AddSpecialEffect(vfx, GetLocationX(loc) + x, GetLocationY(loc) + y)
                BlzSetSpecialEffectAlpha(effect, 120.0)
                -- BlzSetSpecialEffectColor(effect, 80, 80, 255)
                BlzSetSpecialEffectColor(effect, TEST_COLOR[1], TEST_COLOR[2], TEST_COLOR[3])
                BlzSetSpecialEffectScale(effect, 0.6)
                table.insert(vfxList, effect)
            end

            if (range_bitfield & Camp.RangeCraft) ~= 0 then
                local x = BASE_CRAFT_DISTANCE * angle[1]
                local y = BASE_CRAFT_DISTANCE * angle[2]
                local effect = AddSpecialEffect(vfx, GetLocationX(loc) + x, GetLocationY(loc) + y)
                BlzSetSpecialEffectAlpha(effect, 200.0)
                BlzSetSpecialEffectColor(effect, 255, 100, 100)
                BlzSetSpecialEffectScale(effect, 0.6)
                table.insert(vfxList, effect)
            end
        end
        active_radius[player] = vfxList

        Clock.DelayedCallback(get_player_callback(player), 5.0)
    end,

    OnStart = function()
        -- generate cache
        for i=1,ANGLE_DIVS do
            local angle = 2 * (i/ANGLE_DIVS) * 3.1416
            table.insert(angle_cache, {Cos(angle), Sin(angle)})
        end

        local gg_trg = CreateTrigger()
        TriggerRegisterAnyUnitEventBJ(gg_trg, EVENT_PLAYER_UNIT_CONSTRUCT_START)
        TriggerAddAction(gg_trg, on_construct_start)
        gg_trg = CreateTrigger()
        TriggerRegisterAnyUnitEventBJ(gg_trg, EVENT_PLAYER_UNIT_CONSTRUCT_FINISH)
        TriggerAddAction(gg_trg, on_construct_complete)

        gg_trg = CreateTrigger()
        TriggerRegisterAnyUnitEventBJ(gg_trg, EVENT_PLAYER_UNIT_SELECTED)
        TriggerAddAction(gg_trg, on_select_unit)

        Enemy.ListenEvent(on_unit_dead, Enemy.DeathEvent)

        for k,v in pairs(BASE_BUILD_DISTANCE) do
            build_dist[FourCC(k)] = v
            build_dist_squared[FourCC(k)] = v*v
        end
    end
})

convert_property = function(craft_property)
    local res = 0
    if (craft_property & Globals.Const_Craft_Camp) ~= 0 then
        res = res | Camp.RangeConstruction
    end

    if (craft_property & Globals.Const_Craft_Station) ~= 0 then
        res = res | Camp.RangeCraft
    end
    return res
end

on_construct_start = function()
    local u = GetConstructingStructure()
    local p = GetOwningPlayer(u)
    local craft_idx = Craft.GetIndexByUnitConstruct(GetUnitTypeId(u))
    local cancel = nil

    if craft_idx < 1 then -- only apply to defined craft entries
        return
    end

    if active_camps[p] ~= nil then
        local max_dist = get_build_distance(GetUnitTypeId(active_camps[p].Camp), true)
        local dist = DistanceBetweenPointsSquared(GetUnitLoc(active_camps[p].Camp), GetUnitLoc(u))
        if dist > max_dist then
            cancel = GameText.BUILD_FLOAT_CAMPDISTANCE
        end
    else
        if not IsUnitType(u, UNIT_TYPE_TOWNHALL) then
            cancel = GameText.BUILD_FLOAT_CAMP_REQUIRED
        end
    end

    if cancel then
        FloatText.Create(GetPlayerSurvivor(p), cancel, 1.5, FloatText.Red, p)
        -- GameMessageError("Cannot construct here.", GetOwningPlayer(u))
        Item.Give(u, Globals.Craft_ItemResult[craft_idx], 1)
        RemoveUnit(u)
    end
end

on_construct_complete = function()
    local u = GetConstructedStructure()
    local craft_index = Craft.GetIndexByUnitConstruct(GetUnitTypeId(u))
    local player_camp = active_camps[GetOwningPlayer(u)]
    if craft_index > 0 then
        local properties = convert_property(Globals.Craft_Properties[craft_index])
        
        if Craft.HasProperty(craft_index, Globals.Const_Craft_Camp) then
            if player_camp ~= nil then
                Camp.Terminate(GetOwningPlayer(u), "Previous camp destroyed!")
            end
            player_camp = { Structures = {}, Camp = u }
            active_camps[GetOwningPlayer(u)] = player_camp
        else
            table.insert(player_camp.Structures, u)
        end

        if properties > 0 then
            Camp.ShowRadius(u, properties)
        end

        if Craft.HasProperty(craft_index, Globals.Const_Craft_Station) then
            UnitRemoveAbility(u, ABILITY_RALLY)
        end
    end
end

on_select_unit = function()
    local p = GetTriggerPlayer()
    local u = GetTriggerUnit()

    local craft_index = Craft.GetIndexByUnitConstruct(GetUnitTypeId(u))
    if craft_index > 0 then
        local properties = convert_property(Globals.Craft_Properties[craft_index])
        if properties > 0 then
            Camp.ShowRadius(u, properties)
        end
    end
end

get_build_distance = function(unit_class, squared)
    if not squared or squared == nil then
        return build_dist[unit_class] or DEFAULT_BUILD_DISTANCE
    else
        return build_dist_squared[unit_class] or default_build_dist_squared
    end
end

on_unit_dead = function(player, unit, killer)
    local craft_index = Craft.GetIndexByUnitConstruct(GetUnitTypeId(unit))
    local is_camp = craft_index > 0 and Craft.HasProperty(craft_index, Globals.Const_Craft_Camp)
    if is_camp then
        Camp.Terminate(player)
        Craft.CraftAbility(GetPlayerSurvivor(player), CRAFT_FIRECAMP, function(crafted)
            if crafted then
                Item.Give(GetPlayerSurvivor(player), ITEM_FIRECAMP, 1)
            end 
        end)
    else
        if active_camps[player] ~= nil then
            local struct_idx = getIndexHandle(active_camps[player].Structures, unit)
            if struct_idx > 0 then
                table.remove(active_camps[player].Structures, struct_idx)
            end
        end
    end
end

get_player_callback = function(player)
    callback_cache[player] = callback_cache[player] or function() 
        request_count[player] = math.max(0,request_count[player] - 1)
        if request_count[player] == 0 then
            Camp.HideRadius(player) 
        end
    end
    return callback_cache[player]
end