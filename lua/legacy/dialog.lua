local triggers = {}
local callbacks = {}
local actions = {}

local clear_triggers = function(dialogHandle)
    TriggerRemoveAction(triggers[dialogHandle], actions[dialogHandle])
    DestroyTrigger(triggers[dialogHandle])
    callbacks[dialogHandle] = nil
    actions[dialogHandle] = nil
end

local trg_action = function()
    local dialog = GetClickedDialog()
    local button = GetClickedButton()
    callbacks[dialog](GetTriggerPlayer(), button)
    clear_triggers(dialog)
end

local spawn_triggers = function(dialogHandle, func)
    local gg_trg = CreateTrigger()
    TriggerRegisterDialogEvent(gg_trg, dialogHandle)
    actions[dialogHandle] = TriggerAddAction(gg_trg, trg_action)
    triggers[dialogHandle] = gg_trg
    callbacks[dialogHandle] = func or false
end

function InitDialog()

    local listen_dialog = function(dialog, buttons, callback)
        local tmp_trg = CreateTrigger(dialog)

        local tmp_callback = function()
            local clicked = GetClickedButton()
            callback(GetTriggerPlayer(), getIndexHandle(buttons, clicked))
            DestroyTrigger(tmp_trg)
            DialogDestroy(dialog)
        end
        
        TriggerRegisterDialogEvent(tmp_trg, dialog)
        TriggerAddAction(tmp_trg, tmp_callback)
    end

    function ShowDialog(dialogName, player, show_state, text, callback)
        local dialog = _G["udg_Dialog_" .. dialogName .. "_Handle"]
        if dialog == nil then
            EngineError("Unknown dialog " .. dialogName)
            return
        end

        DialogSetMessageBJ(dialog, text or "Confirm")
        DialogDisplayBJ(show_state, dialog, player)
        spawn_triggers(dialog, callback)
    end

    function ShowCustomDialog(player --[[player handle]], message --[[string]], choices --[[array string]], callback --[[callback(player handle, integer)]])
        local diag = DialogCreate()
        local buttons = {}
        DialogSetMessage(diag, message)
        for i=1,#choices do
            table.insert(buttons, DialogAddButton(diag, choices[i], tostring(i)))
        end
        listen_dialog(diag, buttons, callback)
        DialogDisplay(player, diag, true)
    end

    local gg_trg = CreateTrigger()
end