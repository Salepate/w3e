--
-- Amalg Compatibility Plugin for WC3
--

local global_table = rawget(_G, "_G")
local old_package = rawget(global_table, package)
local old_require = rawget(global_table, require)

rawset(global_table, "package", 
{
    preload = {}
})

rawset(global_table, "require", function(packageName)
    package.preload[packageName]()
end)

function RestoreLua()
    rawset(global_table, "package", old_package)
    rawset(global_table, "require", old_require)
end