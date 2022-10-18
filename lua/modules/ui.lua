-- private data
local player_lock = nil

-- module
Module("UI",{
    Top = {
        Resources =
        {
        }
    },

    SetText = function(frame --[[ frame handle ]], text)
        if player_lock ~= nil and GetLocalPlayer() ~= player_lock then
            text = BlzFrameGetText(frame)
        end
        BlzFrameSetText(frame, text)
    end,

    SetPlayerOnly = function(player)
        player_lock  = player
    end,

    SetAllPlayers = function()
        player_lock = nil
    end,
    
    OnStart = function()
        UI.Top.Resources.Gold = BlzGetFrameByName("ResourceBarGoldText", 0)
        UI.Top.Resources.Lumber = BlzGetFrameByName("ResourceBarLumberText", 0)
        UI.Top.Resources.Upkeep = BlzGetFrameByName("ResourceBarUpkeepText", 0)
        UI.Top.Resources.Supply = BlzGetFrameByName("ResourceBarSupplyText", 0)
    end
})