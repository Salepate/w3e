Listener = 
{
    Create = function()
        local listener_map = {}
                    
        local get_listeners = function(code)
            listener_map[code] = listener_map[code] or {}
            return listener_map[code]
        end

        local obj = 
        {
            listen = function(callback, code)
                table.insert(get_listeners(code), callback)
            end,

            invoke  = function(code, arg1, arg2, arg3, arg4, arg5)
                local listeners = get_listeners(code)
                for i=1,#listeners do
                    if listeners[i](arg1, arg2, arg3, arg4, arg5) then
                        break
                    end
                end
            end
        }
        return obj
    end
}