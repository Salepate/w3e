-- Globals
STEP_CUSTOM = 1
STEP_CRAFT  = 2

-- Internal
local quest_list = {}
local activated_quests = {}

-- API
QuestCreator = 
{

    CreateQuest = function(name, desc, icon)
        local quest = {
            Name = name,
            Description = desc,
            Icon = icon,
            Steps = {},
        }
        table.insert(quest_list, quest)
        quest.ID = #quest_list
        return quest
    end,

    AttachTrigger = function(quest_id, quest_step, trigger --[[trigger or Global: Input_Trigger]])
        if not trigger then
            trigger = Globals.Input_Trigger
        end

        if not trigger then
            EngineError("Invalid Trigger for quest " .. quest_id .. " - step " .. quest_step)
        end

        local quest = QuestCreator.GetQuestByID(quest_id)
        local step = quest.Steps[quest_step]
        if not step.Triggers then
            step.Triggers = { }
        end
        table.insert(step.Triggers, trigger)
    end,

    IsActive = function(quest_id)
        return activated_quests[quest_id] ~= nil
    end,
    
    GetQuestByID = function(quest_id)
        return quest_list[quest_id] or false
    end,

    GetStepType = function(quest, step_index)
        return (#quest.Steps >= step_index and quest.Steps[step_index].step_type) or false
    end,

    AddStep = function(quest, step_data)
        table.insert(quest.Steps, step_data)
        return #quest.Steps
    end,

    AddStepDescription = function(quest, step_index, desc_update)
        quest.Steps[step_index].step_description = desc_update
    end,

    GetCraftIndex = function(craft_step) 
        return craft_step.step_data
    end,

    MakeCraftStep = function(craft_index)
        return
        {
            step_type = STEP_CRAFT,
            step_data = craft_index
        }
    end,

    MakeCustomStep = function()
        return 
        {
            step_type = STEP_CUSTOM
        }
    end
}


function InitQuest()
    local attached_quests = {}

    function UpdateQuestProgress(id, current_step, out_trigger)
        local quest_data = QuestCreator.GetQuestByID(id)
        local descIdx = false
        local step = quest_data.Steps[current_step]
        for i=1,math.min(current_step, #quest_data.Steps) do
            local step = quest_data.Steps[i]
            if step.step_description ~= nil then
                descIdx = i
            end
        end
        local questDesc = quest_data.Description
        if descIdx ~= false then
            questDesc = questDesc .. "\n" .. quest_data.Steps[descIdx].step_description
        end
        if step.Triggers then
            for i=1,#step.Triggers do
                TriggerExecute(step.Triggers[i])
            end
        end

        QuestSetDescription(activated_quests[id], questDesc)

        out_trigger = out_trigger or udg_TriggerQuestUpdate

        if out_trigger ~= nil then
            TriggerExecute(out_trigger)
        end
    end

    local InternalCreateQuest = function(id, whichPlayer)
        -- create the UI if wasnt created yet
        local quest_data = QuestCreator.GetQuestByID(id)

        if quest_data ~= nil and activated_quests[id] == nil then
            local quest = CreateQuestBJ(bj_QUESTTYPE_OPT_DISCOVERED, quest_data.Name, quest_data.Description, quest_data.Icon or "ReplaceableTextures\\CommandButtons\\BTNAmbush.blp")
            activated_quests[id] = quest
            UpdateQuestProgress(id, 1, udg_TriggerQuestNew)
        end
        return {
            triggers = {},
            quest_id = id
        }
    end


    function GetOrCreateQuest(whichUnit, quest_id)
        if attached_quests[whichUnit] == nil then
            attached_quests[whichUnit] = InternalCreateQuest(quest_id, GetOwningPlayer(whichUnit))
        end
        return attached_quests[whichUnit]
    end


    function RemoveQuests(whichUnit)
        local quest = attached_quests[whichUnit] or false

        if quest ~= false then
            for i=1,#quest.triggers do
                DestroyTrigger(quest.triggers[i])
            end
            attached_quests[whichUnit] = nil
        end
    end

    function RegisterAbilityCraft(questUnit, targetUnit, craft_index, resultcb)
        local p = GetOwningPlayer(questUnit)
        local quest = attached_quests[questUnit]
        local trg_cast = CreateTrigger()
        UnitAddAbility(targetUnit, udg_Craft_AbilityDummy[craft_index])
        table.insert(quest.triggers, trg_cast)
        local trg_idx = #quest.triggers
        TriggerRegisterAnyUnitEventBJ(trg_cast, EVENT_PLAYER_UNIT_SPELL_CAST)
        TriggerAddAction(trg_cast, function()

            if GetOwningPlayer(GetSpellAbilityUnit()) ~= p then
                return
            end
            if GetSpellAbilityId(GetSpellAbility()) ~= udg_Craft_AbilityDummy[craft_index] then
                return
            end

            local craft_success = Craft.HasIngredients(questUnit, craft_index)
            if not craft_success then
                GameMessageError("|cffff4444Missing Ingredients|r", p)
            else
                Craft.ConsumeIngredients(questUnit, craft_index)
                UnitRemoveAbility(targetUnit, udg_Craft_AbilityDummy[craft_index])
                DestroyTrigger(trg_cast)
                table.remove(quest.triggers, trg_idx)
            end

            resultcb(craft_success)
        end)
    end
end