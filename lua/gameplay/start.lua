-- data
local enumplayer_member = "GetEnumPlayer"
local enumunit_member = "GetEnumUnit"

local unit_map = {}
local player_spawns = {}
local player_ready = {}
local active_chapters = {}
-- local funcs/events
local on_unit_in_range, on_player_select_chapter
local create_class_trigger
-- module
Module("Start", {
    SetSurvivorClass = function(player --[[player handle]])
        UI.SetPlayerOnly(player)
        UI.SetText(UI.Top.Resources.Upkeep, "Survivor")
    end,

    StartMatch = function()
        local enumBack = rawget(_G, enumplayer_member)
        local unitEnumBack = rawget(_G, enumunit_member)

        for player,trigger in pairs(player_spawns) do
            rawset(_G, enumplayer_member, function() return player end)
            rawset(_G, enumunit_member, function() return GetPlayerSurvivor(player) end)
            TriggerExecute(Globals.Start_Spawn_ChapterTrigger[trigger])
        end
        rawset(_G, enumplayer_member, enumBack)
        rawset(_G, enumunit_member, unitEnumBack)
    end,

    SetPlayerSpawn = function(player --[[player handle]], chapter_index)
        player_spawns[player] = chapter_index
        active_chapters[chapter_index] = true
        table.insert(player_ready, player)

        if #player_ready == #W3E.Players then
            if Globals.Start_PlayersReady ~= nil then
                TriggerExecute(Globals.Start_PlayersReady)
            end

            for ch_id in pairs(active_chapters) do
                if Globals.Start_ChapterTrigger[ch_id] ~= nil then
                    TriggerExecute(Globals.Start_ChapterTrigger[ch_id])
                end
            end
            Start.StartMatch()
        else
            GameNotice("Now waiting for other players.", player)
        end
    end,

    RemoveInactives = function()
        for i=1,#W3E.Players do
            local player = W3E.Players[i]

            if getIndex(player_ready, player) == nil then
                GameNotice("Removed Player |cffffcc00" .. GetPlayerName(player) .. "|r (|cffcc4444inactive|r)")
                MeleeDoDefeat(player)
            end
        end
    end,

    RegisterUnitClass = function(unit --[[unit handle]])
        local unit_class = GetUnitTypeId(unit)
        local angle = GetUnitFacing(unit)
        local offset_x = Cos(angle) * 100.0 + GetUnitX(unit)
        local offset_y = Sin(angle) * 100.0 + GetUnitY(unit)
        
        if unit_class ~= UNIT_SURVIVOR then -- skip survivor as only used for stats computing
            local circle = CreateUnit(P_NEUTRAL, UNIT_CIRCLE_STAND, offset_x, offset_y, 0.0)
            unit_map[circle] = unit_class
            create_class_trigger(circle, unit_class)

            FloatText.Create(unit, GetUnitName(unit))
        end

        unit_map[unit_class] = unit
    end,

    GetUnitHandleByClass = function(unit_class --[[unit typeid]])
        return unit_map[unit_class]
    end,

    OnStart = function()
        ProjectSurvive.OnSelecterChapter = on_player_select_chapter

    end
})

-- implems
on_unit_in_range = function(unit, selected_class)
    if GetUnitTypeId(unit) == UNIT_SURVIVOR then
        local p = GetOwningPlayer(unit)
        local loc = GetUnitLoc(unit)
        RemoveUnit(unit)
        local newunit = CreateUnitAtLoc(p, selected_class, loc, 90.0)
        SelectUnitForPlayerSingle(newunit, p)
        SetPlayerSurvivor(p, newunit)
        Equipment.Create(p)
        SpawnPlayerBackpack(p)
        GameNotice("You have selected " .. GetUnitName(newunit), p)
        UI.SetPlayerOnly(p)
        UI.SetText(UI.Top.Resources.Upkeep, GetUnitName(newunit))
    end
end

on_player_select_chapter = function(player, chapter_index)
    --TODO: ignore chapter 2/3 for now, later check for unlocks
    if chapter_index > 1 then
        return
    end

    local trigger = Globals.Start_Chapter_PlayerTrigger[chapter_index]
    if trigger == nil then
        EngineError("Unknown Trigger for chapter " .. tostring(chapter_index))
    else
        ProjectSurvive.SetWindowChapterSelect(false, player)
        local enumBack = rawget(_G, enumplayer_member)
        rawset(_G, enumplayer_member, function() return player end)
        TriggerExecute(trigger)
        rawset(_G, enumplayer_member, enumBack)
    end
end
    
create_class_trigger = function(circle_unit, unit_class)
    local gg_trg = CreateTrigger()
    TriggerRegisterUnitInRangeSimple(gg_trg, 80.0, circle_unit)
    TriggerAddAction(gg_trg, function() on_unit_in_range(GetTriggerUnit(), unit_class) end)
end