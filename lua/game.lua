-- w3e
require "engine/war3engine"
-- legacy includes (aka not ported to modules)
require "legacy/inventory"
require "legacy/command"
require "legacy/quest"
require "legacy/dialog"
require "legacy/backpack"
require "legacy/workshop"
require "legacy/generator"
require "legacy/refinery"
-- engine modules
require "modules/globals"
require "modules/clock"
require "modules/lock"
require "modules/item"
require "modules/enemy"
require "modules/respawn"
require "modules/ui"
require "modules/floattext"
require "modules/cinematic"
-- gameplay modules
require "gameplay/playerscale"
require "gameplay/cast"
require "gameplay/region"
require "gameplay/progression"
require "gameplay/start"
require "gameplay/equipment"
require "gameplay/craft"
require "gameplay/night_event"
require "gameplay/camp"
-- legacy module
Module("Legacy_Engine", 
{
    OnStart = function()
        -- Engine
        InitCommand() -- command.lua
        InitQuest() -- quest.lua
        InitDialog() -- dialog.lua
        -- Gameplay
        InitBackpack() -- gameplay/backpack.lua
        InitWorkshop() -- workshop/workshop.lua
        for i=1,MAX_PLAYER do
            local whichPlayer = Player(i-1)
            if GetPlayerSlotState(whichPlayer) == PLAYER_SLOT_STATE_PLAYING and GetPlayerController(whichPlayer) == MAP_CONTROL_USER then
                udg_Host = whichPlayer
                break
            end
        end
    end
})