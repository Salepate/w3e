-- data
local all_players

Module("Cinematic",
{
    PlayerName = function(player)
        local id

        if type(player) == "number" then
                id = player
                player = Player(player)
        else
            id = GetConvertedPlayerId(player)
        end

        local color = PLAYER_COLOR_TAG[id]

        return "|cff" .. color .. W3E.GetPlayerName(player) .."|r"
    end,

    UnitLine = function(unit, message, toAll --[[false or integer]] )
        if not unit then
            return
        end
        local player = GetOwningPlayer(unit)
        Cinematic.PlayerLine(player, message, toAll)
    end,


    PlayerLine = function(player, message, toAll --[[false or integer]])
        if not player then
            return
        end
        local message = Cinematic.PlayerName(player) .. " : " .. message

        if not toAll then
            DisplayTimedTextToPlayer(player, 0, 0, 5.0, message)
        else
            for i=1,#WorldRegion.PlayerGroups[toAll] do
                DisplayTimedTextToPlayer(GetOwningPlayer(WorldRegion.PlayerGroups[toAll][i]), 0.0, 0.0, 5.0, message)
            end
        end
    end,

    OnStart = function()
        all_players = GetPlayersAll()
    end
})