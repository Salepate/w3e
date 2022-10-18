-- local 
local p_count_fast

Module("PlayerScale",
{
    GetTimeFactor = function(worldzone)
        return RESPAWN_TIME_SCALE[p_count_fast(worldzone)]
    end,

    OnStart = function()
        p_count_fast = WorldRegion.CountPlayer -- skip metatable access since this will be called intensively

        local max_idx = #RESPAWN_TIME_SCALE
        for i=max_idx+1, #W3E.Players do
            RESPAWN_TIME_SCALE[i] = RESPAWN_TIME_SCALE[max_idx]
        end
    end
})