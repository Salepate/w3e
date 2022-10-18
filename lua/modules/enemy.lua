-- TODO: Rename to Unit
-- private data
local game_db = {}
local listeners = Listener.Create()
-- private events/funcs
local on_creature_dying, compute_loot, compute_lootv2

Module("Enemy",
{
    DeathEvent = 1,
    
    ListenEvent = function(callback --[[func(player, unit, killing unit)]], eventType)
        listeners.listen(callback, eventType)
    end,

    Register = function()
        local dbEntry = {}
        if Globals.EnemyItemCount > 0 then
            dbEntry.drops = {}
            for i=1,Globals.EnemyItemCount do
                table.insert(dbEntry.drops, {Globals.EnemyItemPool[i], Globals.EnemyItemWeight[i], Globals.EnemyItemUserData[i] or false})
            end
        end
    
        game_db[Globals.Input_UnitClass] = dbEntry
    end,

    OnStart = function()
        local trg_unit_die = CreateTrigger()
        TriggerRegisterAnyUnitEventBJ(trg_unit_die, EVENT_PLAYER_UNIT_DEATH)
        TriggerAddAction(trg_unit_die, on_creature_dying)
    end
})

-- private declarations
on_creature_dying = function()
    local whichUnit = GetDyingUnit()
    local owner = GetOwningPlayer(whichUnit)
    local whichType = GetUnitTypeId(whichUnit)
    local killer = GetKillingUnit()
    compute_loot(killer, whichType, GetUnitLoc(whichUnit))
    listeners.invoke(Enemy.DeathEvent, owner, whichUnit, killer)
end

compute_loot = function(killer, unit_type, loc)
    local dbEntry = game_db[unit_type] or false
    if dbEntry ~= false and #dbEntry.drops > 0 then
        for i=1,#dbEntry.drops do
            local drop = dbEntry.drops[i]
            local val = GetRandomReal(0.0, 100.0)
            if val <= drop[2] then
                local item = Item.Spawn((drop[3] > 0 and GetOwningPlayer(killer)) or nil, loc, drop[1], 1, drop[3])
            end
        end
    end
end