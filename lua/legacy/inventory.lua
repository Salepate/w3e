--  Module
Module("Inventory",
{
    GetSlot = function(unit, item)
        for i=0,5 do
            if UnitItemInSlot(unit, i) == item then
                return i
            end
        end
        return -1
    end
})