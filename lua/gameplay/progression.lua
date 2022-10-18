-- private data
local spawned_recipes = {}
local xp_range_squared = 1
-- private funcs/callbacks
local on_item_pickup, on_item_spawn, on_unit_death
-- Module
Module("Progression",
{
    OnStart = function()
        xp_range_squared = HERO_XP_RANGE * HERO_XP_RANGE
        Item.ListenEvent(on_item_spawn, Item.SpawnEvent)
        Item.ListenEvent(on_item_pickup, Item.PickUpEvent)
        Enemy.ListenEvent(on_unit_death, Enemy.DeathEvent)
    end
})

-- implems
on_unit_death = function(player, unit, killer)
    local isEnemy = IsUnitEnemy(killer, player) and GetPlayerController(GetOwningPlayer(killer)) == MAP_CONTROL_USER
    if isEnemy and killer ~= nil and IsUnitType(killer, UNIT_TYPE_STRUCTURE) then

        local lv = GetUnitLevel(unit) or GetHeroLevel(unit)
        local xp_gain = 0
        if lv <= #HERO_XP_NORMAL_TABLE then
            xp_gain = HERO_XP_NORMAL_TABLE[lv]
        else
            xp_gain = lv * HERO_XP_NORMAL_LEVEL_FACTOR + HERO_XP_NORMAL_CONSTANT
        end

        xp_gain = math.max(0, xp_gain / 2.0)

        for i=1,#udg_Survivors do
            local playerSurvivor = udg_Survivors[i]
            if true then -- TODO: Check if not a griefer/rogue
                local dist = DistanceBetweenPointsSquared(GetUnitLoc(killer), GetUnitLoc(playerSurvivor))

                if dist <= xp_range_squared then
                    AddHeroXP(playerSurvivor, xp_gain, true)
                end
            end
        end
    end
end

on_item_spawn = function(player, unit, item, item_class)
    local userData = GetItemUserData(item)
    if item_class == ITEM_LEARN_RECIPE then
        -- TODO: BlzSetItemName() seems to be broken
        local owner = Item.GetOwner(item)
        spawned_recipes[owner] = spawned_recipes[owner] or {}

        if userData > 0 then
            -- player already has?
            if spawned_recipes[owner][userData] or Lock.IsUnlocked(owner, userData) then
                Item.Destroy(item)
                return true
            else
                spawned_recipes[owner][userData] = true
                BlzSetItemName(item, GetItemName(item) .. ": " .. Lock.GetName(userData))
            end
        else
            Item.Destroy(item)
            return true -- destroy item since not relevant
        end
    end
end

on_item_pickup = function(player, unit, item, item_class)
    local userData = GetItemUserData(item)
    if item_class == ITEM_LEARN_RECIPE then
        if userData > 0 then
            if not Lock.IsUnlocked(player, userData) then
                FloatText.Create(unit, "New Recipe: " .. Lock.GetName(userData), 3.0, FloatText.Blue, player)
                Lock.Unlock(player, userData)
            end
        end
        Item.Destroy(item)
        return true
    end
    return false
end