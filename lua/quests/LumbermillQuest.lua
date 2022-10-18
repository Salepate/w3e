local lm_quest = QuestCreator.CreateQuest(
    "Restart the lumber mill", 
    "There is a fuel generator that is empty, we need to find some gas around here.",
    "ReplaceableTextures\\CommandButtons\\BTNHumanLumberMill.blp")
local first_step = QuestCreator.AddStep(lm_quest, QuestCreator.MakeCustomStep()) -- 1x prepare package quest
local global_progress = 1 

QuestLumberMill = lm_quest.ID

TheLumberMill = 
{
    AdvanceQuest = function(self)
    end,

    SetupStep = function(self, survivor, assistantUnit)
    end,

    AttachAssistant = function(self, assistantUnit)
        local survivor = GetPlayerSurvivor(GetOwningPlayer(assistantUnit))

        if not QuestCreator.IsActive(QuestLumberMill) then
            Cinematic.UnitLine(survivor, "There is a lumbermill up north, we may use it to refine wood!", 1)
        end
        local quest = GetOrCreateQuest(survivor, lm_quest.ID)
        self:SetupStep(survivor, assistantUnit)
    end
}

