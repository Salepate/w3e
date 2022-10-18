-- !enemy <unit code>
function SpawnEnemyCmd(whichPlayer, args, unit_code, unit_count)
    local player_unit = GetPlayerSurvivor(whichPlayer)
    local unit_loc = GetUnitLoc(player_unit)

    if unit_count == nil then
        CreateUnitAtLoc(HOSTILE_FORCES[1], FourCC(unit_code), unit_loc, 0.0)
    else
        for i=1,tonumber(unit_count) do
            CreateUnitAtLoc(HOSTILE_FORCES[1], FourCC(unit_code), unit_loc, 0.0)
        end
    end
end

-- !control [<player>]
function ControlCmd(player, args, target_player)
    target_player = ConvertedPlayer(tonumber(target_player))
    SetPlayerAllianceBJ( target_player, ALLIANCE_SHARED_VISION, true, player )
    SetPlayerAllianceBJ( target_player, ALLIANCE_SHARED_CONTROL, true, player )
    SetPlayerAllianceBJ( target_player, ALLIANCE_SHARED_SPELLS, true, player )
    SetPlayerAllianceBJ( target_player, ALLIANCE_SHARED_ADVANCED_CONTROL, true, player )
end

-- !ally [<player>] <unit code> [<unit count>]
function SpawnAllyCmd(player, args, forplayer, unit_code, unit_count)

    local player_unit = GetPlayerSurvivor(player)
    local unit_loc = GetUnitLoc(player_unit)

    if not unit_count  then
        unit_count = unit_code
        unit_code = forplayer
        forplayer = player
    else
        forplayer = ConvertedPlayer(tonumber(forplayer))
    end

    if unit_count == nil then
        CreateUnitAtLoc(forplayer, FourCC(unit_code), unit_loc, 0.0)
    else
        for i=1,tonumber(unit_count) do
            CreateUnitAtLoc(forplayer, FourCC(unit_code), unit_loc, 0.0)
        end
    end
end

-- !item <item name | item id>
function SpawnItemCmd(whichPlayer, args, itemName, itemCount)
    if args < 1 then
        EngineError("Command error !item - item name or id required", whichPlayer)
        return
    end

    local whichUnit = GetPlayerSurvivor(whichPlayer)
    Item.Spawn(whichPlayer, GetUnitLoc(whichUnit), Item.GetIdFromName(itemName), itemCount)    
end

-- !time <time>
function SetTime(whichPlayer, args, newTime)
    if args ~= 1 then
        EngineError("Command error !time - time value required", whichPlayer)
        return
    end
    newTime = tonumber(newTime)
    SetTimeOfDay(newTime)
    NightEvent.SetNightEvent(newTime >= 0.0 and newTime < 6.0)
end

-- !timescale <scale>
function SetTimeScale(whichPlayer, args, newScale)
    if args ~= 1 then
        EngineError("Command error !timescale - scale value required", whichPlayer)
        return
    end
    SetTimeOfDayScale(tonumber(newScale))
end


function InitCommand()
    local trg_cmd = CreateTrigger()
    local commands = {}

    for i=1,MAX_PLAYER do
        local whichPlayer = Player(i-1)
        if GetPlayerSlotState(whichPlayer) == PLAYER_SLOT_STATE_PLAYING then
            TriggerRegisterPlayerChatEvent(trg_cmd, whichPlayer, "!", false)
        end
    end

    function RegisterCommand(cmdName, callback)
        commands[cmdName] = callback
    end

    function ParseArgs(message)
        local args = {}
        local idx = 2
        local space_bytecode = string.byte(" ")
        local index_pairs = {}

        for i=2, #message do
            if message:byte(i) == space_bytecode then
                if idx ~= 1 then
                    table.insert(index_pairs,idx)
                    table.insert(index_pairs,i-1)
                    idx = -1
                end
            else
                if idx == -1 then
                    idx = i
                end
            end
        end
        -- last arg
        if idx ~= -1 then
            table.insert(index_pairs,idx)
            table.insert(index_pairs,#message)
        end
        for i=1,#index_pairs - 1,2 do
            table.insert(args, message:sub(index_pairs[i], index_pairs[i+1]))
        end
        return args
    end

    local function onPlayerChat()
        local msg = GetEventPlayerChatString()
        local whichPlayer = GetTriggerPlayer()

        if msg:sub(1,1) == "!" then
            local args = ParseArgs(msg)
            local commandName = args[1]
            local cmd = nil

            if #args >= 1 then
                cmd = commands[commandName] or nil
            end
            
            if cmd ~= nil then
                table.remove(args, 1)
                cmd(whichPlayer, #args, args[1] or nil, args[2] or nil, args[3] or nil, args[4] or nil) -- unpack() seems broken
            else
                EngineError("Uknown command " .. commandName, whichPlayer)
            end


        end
    end
    TriggerAddAction(trg_cmd, onPlayerChat)
end