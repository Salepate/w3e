--[[ Trigger helpers ]]--

-- returns content stored in Global : RegionInput [region handle]
function FetchRegion()
    return udg_RegionInput
end

-- returns content stored in Global : UnitInput [unit handle]
function FetchUnit()
    return udg_UnitInput
end

function FetchItemType()
    return udg_ItemTypeInput
end
-- stores cond result as boolean in Global : ConditionResult [bool]
function TestCode(cond)
    udg_ConditionResult = (cond and true) or false
end

--[[ Text Messages ]]--
function GameNotice(message, toPlayer)
    local message = "Notice: |cff44ff44" .. message .. "|r"

    if toPlayer == nil then
        print(message)
    else
        DisplayTimedTextToPlayer(toPlayer, 0, 0, 8.0, message)
    end
end

function GameMessageError(message, toPlayer)
    local message = "|cffff4444" .. message .. "|r"

    if toPlayer == nil then
        print(message)
    else
        DisplayTimedTextToPlayer(toPlayer, 0, 0, 8.0, message)
    end
end

function EngineError(message, toPlayer)
    local message = "[|cffff4444Error|r]" .. message

    if toPlayer == nil then
        print(message)
    else
        DisplayTimedTextToPlayer(toPlayer, 0, 0, 8.0, message)
    end
end

--[[ code helpers ]]--

function DistanceBetweenPointsSquared(loc1, loc2)

    local x1 = GetLocationX(loc1)
    local x2 = GetLocationX(loc2)
    local y1 = GetLocationY(loc1)
    local y2 = GetLocationY(loc2)

    local dx = x2 - x1
    local dy = y2 - y1

    return dx*dx + dy*dy
end

function getIndexHandle(tab, val)
    local index = 0
    for i, v in ipairs (tab) do 
        if (v == val) then
          index = i
          break
        end
    end
    return index
end

function getIndex(tab, val)
    local index = nil
    for i, v in ipairs (tab) do 
        if (v.id == val) then
          index = i 
          break
        end
    end
    return index
end

--[[ Survivor ]]-- TODO: Convert to module
local player_survivors = {}

function SetPlayerSurvivor(whichPlayer, whichUnit)
    udg_Survivors[GetConvertedPlayerId(whichPlayer)] = whichUnit
    player_survivors[GetConvertedPlayerId(whichPlayer)] = whichUnit
    table.insert(udg_AllyGroup, whichUnit) -- for AI
    udg_AI_GroupSize = #udg_AllyGroup

    --  death trigger
    local death_trg = CreateTrigger()
    TriggerRegisterUnitEvent(death_trg, whichUnit, EVENT_UNIT_DEATH)
    TriggerAddAction(death_trg, function() 
        GameNotice(Cinematic.PlayerName(whichPlayer) ..  " has been killed!")
        Equipment.Destroy(whichPlayer)
        Camp.Terminate(whichPlayer, "Camp has been destroyed!")
        local world_zone = WorldRegion.GetSurvivorWorldzone(whichUnit)
        local survivors = WorldRegion.GetWorldzoneSurvivors(world_zone)
        WorldRegion.RemoveSurvivor(whichUnit)

        for i=1,#survivors do
            local owner = GetOwningPlayer(survivors[i])
            if owner ~= whichPlayer then
                UnitShareVision(survivors[i], whichPlayer, true)
            end
        end
    end)

end

function IsSurvivor(whichUnit)
    return GetPlayerSurvivor(GetOwningPlayer(whichUnit)) == whichUnit
end

function GetPlayerSurvivor(whichPlayer)
    return player_survivors[GetConvertedPlayerId(whichPlayer)]
end