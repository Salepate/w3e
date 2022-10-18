require "game"

W3E.Initialize()

-- Creating Respawns
--[[
Respawn.SetSpawnType(Respawn.Enemy)
Respawn.CreateRespawn(5, 5, 10)

for i=1,100 do
    Respawn.OnTick(0.5)
end
]]