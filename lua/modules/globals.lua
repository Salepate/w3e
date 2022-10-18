Module("Globals", {})

local GlobalsMetatable = 
{
    __index = function(table, key)
        local globalName = "udg_" .. key
        return rawget(_G, globalName)
    end
}

setmetatable(Globals, GlobalsMetatable)