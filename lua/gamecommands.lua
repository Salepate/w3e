-- !share [<player id>] -- allow someone else to control your units
function ShareCommand(target_player, args, player)
    player = ConvertedPlayer(tonumber(player))
    SetPlayerAllianceBJ( target_player, ALLIANCE_SHARED_CONTROL, true, player )
    SetPlayerAllianceBJ( target_player, ALLIANCE_SHARED_SPELLS, true, player )
    SetPlayerAllianceBJ( target_player, ALLIANCE_SHARED_ADVANCED_CONTROL, true, player )
end
