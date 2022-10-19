require "engine/static"
require "engine/module"
require "engine/listener"

-- private
local format_player_name

W3E = (function()
    local modules = {}
    local module_set = {}
    local players = {}
    local playerNames = {}
    local host = nil

    return
    {
        HasModule = function(moduleName)
            return module_set[moduleName] ~= nil
        end,

        RegisterModule = function(module)
            table.insert(modules, module)
            rawset(_G, module.Name, module)
        end,

        GetPlayerName = function(player)
            if type(player) == "number" then
                player = Player(player)
            end

            return playerNames[player]
        end,

        Host = host,
        Players = players,

        Initialize = function()
            for i=1,24 do
                local player = Player(i-1)
                if GetPlayerSlotState(player) == PLAYER_SLOT_STATE_PLAYING and GetPlayerController(player) == MAP_CONTROL_USER then
                    if not host then
                        host = player
                    end
                    table.insert(players, player)
                    playerNames[player] = format_player_name(GetPlayerName(player))
                end
            end

            for i=1,#modules do
                local module = modules[i]
                module_set[module.Name] = true
                if modules[i].OnStart then
                    modules[i].OnStart()
                end
            end
        end
    }
end)()

format_player_name = function(playerName)
    local nameLength = #playerName
    local name

    if nameLength > 5 and playerName:sub(nameLength - 4, nameLength - 4) == "#"  then
        name = playerName:sub(1, nameLength - 5)
    else
        name = playerName
    end

    return name
end