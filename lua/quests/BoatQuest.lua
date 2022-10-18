local boat_quest = QuestCreator.CreateQuest("Repairing the boat", "Perhaps building the boat is our only escape from this dangerous isle.", "ReplaceableTextures\\CommandButtons\\BTNJuggernaut.blp")
local first_craft_step = QuestCreator.AddStep(boat_quest, QuestCreator.MakeCraftStep(2)) -- 5x Planks
local last_craft_step = QuestCreator.AddStep(boat_quest, QuestCreator.MakeCraftStep(3)) -- 1x Main Sail
local package_step = QuestCreator.AddStep(boat_quest, QuestCreator.MakeCustomStep()) -- 1x prepare package quest

QuestCreator.AddStepDescription(boat_quest, first_craft_step, "We need a few materials to repair the boat located on the east coast of this island.\nCraft 5 Planks.")
QuestCreator.AddStepDescription(boat_quest, last_craft_step, "The boat is almost functional, we need to find a mast before sailing!")
QuestCreator.AddStepDescription(boat_quest, package_step, "Hurray the boat is ready for sailing, but I need some provisions first!")
local global_progress = 1 -- up to #boat_quest.Steps
local is_demo = true

QuestTheBoat = boat_quest.ID
QuestTheBoatStepMast = last_craft_step

local messages = { 
    "The boat is being repaired",
    "The mainsail has been attached, prepare a backpack before sailing!"
 }

local target_region = nil
local repaired_boat_region = nil
local damaged_boat_doodad = nil
local repaired_boat_type = FourCC("B001")

local sail_callback = function(player, button)
    if button == udg_Dialog_Confirm_BtnValidate and target_region ~= nil then
        if is_demo then
            PlayTeaser(player)
            return
        end
        local survivor = GetPlayerSurvivor(player)
        local target_loc = GetRandomLocInRect(target_region)
        HideBackpack(player)
        SetUnitPositionLoc(survivor, target_loc)
        SetCameraPositionForPlayer(player, GetLocationX(target_loc), GetLocationY(target_loc))
    end
end

TheBoat = 
{
    IsCraftingRequired = function(self) 
        return QuestCreator.GetStepType(boat_quest, global_progress) == STEP_CRAFT
    end,

    IsReadyToSail = function(self)
        return global_progress >= #boat_quest.Steps
    end,

    SetBoatSpawn = function(self, region)
        target_region = region
    end,

    SetDamagedBoat = function(self, doodad)
        damaged_boat_doodad = doodad
    end,

    SetRepairedBoatSpawn = function(self, region)
        repaired_boat_region = region
    end,

    PromptSail = function(self, player)
        ShowDialog("Confirm", player, true, "Embark on boat?", sail_callback)
        GameNotice("|cffffcc00 You cannot get back to this isle once you set sail!|r", player)
    end,

    AdvanceQuest = function(self)
        if global_progress <= #messages then
            GameNotice(messages[global_progress])
        end

        global_progress = global_progress + 1
        UpdateQuestProgress(boat_quest.ID, global_progress)

        if global_progress == package_step then
            RemoveDestructable(damaged_boat_doodad)
            local loc = GetRectCenter(repaired_boat_region)
            CreateDestructableLoc(repaired_boat_type, loc, 90.0, 1.0, 0)
        end
    end,

    SetupStep = function(self, survivor, assistantUnit)
        if self:IsCraftingRequired() then
            local craft = QuestCreator.GetCraftIndex(boat_quest.Steps[global_progress])
            RegisterAbilityCraft(survivor, assistantUnit, craft, function(success)
                if success then
                    self:AdvanceQuest()
                    self:SetupStep(survivor, assistantUnit)
                end
            end)
        end
    end,

    AttachAssistant = function(self, assistantUnit)
        local survivor = GetPlayerSurvivor(GetOwningPlayer(assistantUnit))
        local quest = GetOrCreateQuest(survivor, boat_quest.ID)
        self:SetupStep(survivor, assistantUnit)
    end
}

