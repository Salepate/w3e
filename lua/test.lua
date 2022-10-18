-- w3E
require "engine/war3engine"

-- project specific modules
require "gameplay/playerscale"
require "gameplay/region"
require "modules/respawn"
-- engine modules
require "modules/globals"
require "modules/clock"
require "modules/lock"
require "modules/item"
require "modules/enemy"
require "modules/ui"
require "modules/floattext"
require "modules/cinematic"
-- legacy
require "legacy/command"

Module("LegacyModule", 
{
    OnStart = function()
        InitCommand()
    end
})