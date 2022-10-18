--
-- Unlock Module
-- Author: Salepate
-- Description: Simple progression unlock system, locks must be registered before (recommended map init) module start (at 0.5s gametime)
--

-- Private data
local locks = {}
local player_unlocks = {}
local lockpairs = nil
-- Private funcs/callbacks
local init_player

-- Module
Module("Lock",
{
    Unit = 1,

    Register = function(lockType --[[ integer (Unit)]], lockCode --[[ string (will be FourCCed)]], lockIdentifier --[[ integer unique id]], lockName --[[string human text]])
        locks[lockIdentifier] = {Type = lockType, WidgetClass = FourCC(lockCode), Name = lockName }
    end,

    GetName = function(identifier)
        return locks[identifier].Name
    end,

    IsUnlocked = function(player, lockIdentifier)
        return player_unlocks[lockIdentifier] == true
    end,

    Unlock = function(player, lockIdentifier --[[integer unique id]])
        local lock = locks[lockIdentifier]

        if not player_unlocks[player][lockIdentifier] then
            player_unlocks[player][lockIdentifier] = true

            if lock.Type == Lock.Unit then
                SetPlayerUnitAvailableBJ(lock.WidgetClass, true, player)
            end
        end
    end,

    OnStart = function()
        local lockarray = {}
        for k,v in pairs(locks) do
            table.insert(lockarray, v)
        end
        for i=1,#W3E.Players do
            init_player(W3E.Players[i], lockarray)
        end
    end,
})

init_player = function(player, lockarray)
    player_unlocks[player] = {}
    for i=1,#lockarray do
        local lock = lockarray[i]
        if lock.Type == Lock.Unit then
            SetPlayerUnitAvailableBJ(lock.WidgetClass, false, player)
        end
    end
end