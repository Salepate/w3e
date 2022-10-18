-- private data
local period_map = {}
local callbacks = {}
local delayed_callbacks = {}
-- private func/events
local create_callback_table, on_tick

Module("Clock", {
    Register = function(callback, period)
        period_map[callback] = period
        callbacks[period] = callbacks[period] or create_callback_table()
        table.insert(callbacks[period].callbacks, callback)
    end,

    DelayedCallback = function(callback, delay)
        for i=1,#delayed_callbacks do
            if delay < delayed_callbacks[i][2] then
                table.insert(delayed_callbacks, i, {callback, delay})
                return
            end
        end

        table.insert( delayed_callbacks, {callback, delay} )
    end,

    Remove = function(callback)
        local period = period_map[callback] or nil
    
        if period ~= nil then
            period_map[callback] = nil
            local cbtable = callbacks[period].callbacks
            table.remove(cbtable, getIndex(cbtable, callback))
        end
    end,

    OnStart = function()
        local trg_clock = CreateTrigger()
        TriggerRegisterTimerEventPeriodic(trg_clock, 0.5)
        TriggerAddAction(trg_clock, on_tick)
    end
})

create_callback_table = function()
    return {
        callbacks = {},
        clock = 0.0
    }
end

on_tick = function()
    local delta = 0.5

    for i=#delayed_callbacks,1,-1 do
        local delay = delayed_callbacks[i][2] - delta
        if delay <= 0 then
            delayed_callbacks[i][1]()
            table.remove(delayed_callbacks,i)
        else
            delayed_callbacks[i][2] = delay
        end
    end

    for k in pairs(callbacks) do
        local table = callbacks[k]
        table.clock = table.clock + delta

        if table.clock >= k then
            table.clock = table.clock - k
            for i=1,#(table.callbacks) do
                table.callbacks[i](k)
            end
        end
    end
end