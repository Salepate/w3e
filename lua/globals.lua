---------------------------------------------------------
-- W3E Globals
---------------------------------------------------------

-- player color codes
PLAYER_COLOR_TAG = {
    "ff0303","0042ff","1ce6b9","540081","fffc00","fe8a0e","20c000","e55bb0", -- 1 > 8
    "959697","7ebff1","106246","4a2a04","9b0000","0000c3","00eaff","be00fe", -- 9 > 16
    "ebcd87","f8a48b","bfff80","dcb9eb","282828","ebf0ff","00781e","a46f33"} -- 17 > 24
-- maximum human players
MAX_PLAYER = 8
-- ingame time scale
DAYTIME_FACTOR = 0.66
NIGHTTIME_FACTOR = 0.33
-- item stack limit
MAX_STACK = 20
-- Array of enemy players
HOSTILE_FORCES = { Player(23) }
--[[code constants]]--
ORDER_IDLE = 0
ORDER_ATTACK = 851983
ORDER_STOP = 851972
ORDER_CANCEL = 851976
P_NEUTRAL = Player(PLAYER_NEUTRAL_PASSIVE)

-- cast.lua
UNIT_DUMMY_CASTER = FourCC("h00K")
UNIT_DUMMY_CASTER_AGGRO = FourCC("h00P")
UNIT_DUMMY_TARGET = FourCC("h00L")

-- must be identical to Gameplay Constants to keep consistency
HERO_XP_RANGE = 800.0
HERO_XP_NORMAL_CONSTANT = 2.0
HERO_XP_NORMAL_LEVEL_FACTOR = 2.0
HERO_XP_NORMAL_TABLE = {1}

---------------------------------------------------------
-- Project: Survive
---------------------------------------------------------

CRAFT_FIRECAMP = 1 -- Iterator index

ABILITY_CRAFT_FIRECAMP = FourCC("A00P")
ABILITY_RALLY = FourCC("ARal")

ITEM_EMPTY_DUMMY = FourCC("I00H")
ITEM_FIRECAMP = FourCC("I000")
ITEM_LEARN_RECIPE = FourCC("I00M")

UNIT_CIRCLE_STAND = FourCC("n003")
UNIT_EQUIPMENT = FourCC("H00F")
UNIT_SURVIVOR = FourCC("H000")

-- night_event.lua
UPGRADE_CREEP = { FourCC("R000") }

-- playerscale.lua 
-- increase with player actives on the isle
RESPAWN_TIME_SCALE = { 1.0, 1.05, 1.2, 1.5 } -- 100%, 105%, 120%, 150% (cap)


--  camp.lua
BASE_BUILD_DISTANCE =
{
    h001 = 400.0, -- Small Campment
    h00O = 500.0, -- Hideout
}
-- base distance to station when crafting
BASE_CRAFT_DISTANCE = 200.0
-- additional margin for visual effects
BUILD_DISTANCE_VISUAL_MARGIN = 50.0