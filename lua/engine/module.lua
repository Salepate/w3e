
local ModuleMetatable = 
{
    __index = function(table, key)
        local baseVal = rawget(table, key)
        if baseVal ~= nil then
            return baseVal
        else
            local module_tbl = rawget(table, "Table")
            return module_tbl and module_tbl[key]
        end
    end
}

Module = function(module_name, initialize_func)
    local module = {Name = module_name, Table = initialize_func}
    setmetatable(module, ModuleMetatable)
    W3E.RegisterModule(module)
end