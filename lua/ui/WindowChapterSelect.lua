WindowChapterSelect = nil 
TriggerWindowChapterSelect = nil 
ChapterName = nil 
TriggerChapterName = nil 
ButtonCh01 = nil 
BackdropButtonCh01 = nil 
TriggerButtonCh01 = nil 
ButtonCh02 = nil 
BackdropButtonCh02 = nil 
TriggerButtonCh02 = nil 
ButtonCh03 = nil 
BackdropButtonCh03 = nil 
TriggerButtonCh03 = nil 
TooltipPrologue = nil 
TriggerTooltipPrologue = nil 
TooltipDF = nil 
TriggerTooltipDF = nil 
TooltipMekanika = nil 
TriggerTooltipMekanika = nil 
TooltipPrologueText = nil 
TriggerTooltipPrologueText = nil 
TooltipDFText = nil 
TriggerTooltipDFText = nil 
TooltipMekanikaText = nil 
TriggerTooltipMekanikaText = nil 

ProjectSurvive = {}
ProjectSurvive.ButtonCh01Func = function() 
    BlzFrameSetEnable(ButtonCh01, false) 
    BlzFrameSetEnable(ButtonCh01, true) 
    ProjectSurvive.OnSelecterChapter(GetTriggerPlayer(), 1)
end 
 
ProjectSurvive.ButtonCh02Func = function() 
    BlzFrameSetEnable(ButtonCh02, false) 
    BlzFrameSetEnable(ButtonCh02, true) 
    -- ProjectSurvive.OnSelecterChapter(GetTriggerPlayer(), 2)
end 
 
ProjectSurvive.ButtonCh03Func = function() 
    BlzFrameSetEnable(ButtonCh03, false) 
    BlzFrameSetEnable(ButtonCh03, true) 
    -- ProjectSurvive.OnSelecterChapter(GetTriggerPlayer(), 3)
end 
 
ProjectSurvive.SetWindowChapterSelect = function(state, player)
    local base_state = BlzFrameIsVisible(WindowChapterSelect)

    if player == nil or GetLocalPlayer() == player then
        base_state = state
    end

    BlzFrameSetVisible(WindowChapterSelect, base_state)
end

ProjectSurvive.Initialize = function()

WindowChapterSelect = BlzCreateFrame("QuestButtonDisabledBackdropTemplate", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 0, 0)
BlzFrameSetAbsPoint(WindowChapterSelect, FRAMEPOINT_TOPLEFT, 0.300000, 0.400000)
BlzFrameSetAbsPoint(WindowChapterSelect, FRAMEPOINT_BOTTOMRIGHT, 0.500000, 0.300000)

ChapterName = BlzCreateFrameByType("TEXT", "name", WindowChapterSelect, "", 0)
BlzFrameSetPoint(ChapterName, FRAMEPOINT_TOPLEFT, WindowChapterSelect, FRAMEPOINT_TOPLEFT, 0.0000, -0.0072500)
BlzFrameSetPoint(ChapterName, FRAMEPOINT_BOTTOMRIGHT, WindowChapterSelect, FRAMEPOINT_BOTTOMRIGHT, 0.0000, 0.062750)
BlzFrameSetText(ChapterName, "|cff44ff44Select Chapter|r")
BlzFrameSetEnable(ChapterName, false)
BlzFrameSetScale(ChapterName, 1.00)
BlzFrameSetTextAlignment(ChapterName, TEXT_JUSTIFY_CENTER, TEXT_JUSTIFY_MIDDLE)

ButtonCh01 = BlzCreateFrame("IconButtonTemplate", WindowChapterSelect, 0, 0)
BlzFrameSetAbsPoint(ButtonCh01, FRAMEPOINT_TOPLEFT, 0.345000, 0.345000)
BlzFrameSetAbsPoint(ButtonCh01, FRAMEPOINT_BOTTOMRIGHT, 0.375000, 0.315000)

BackdropButtonCh01 = BlzCreateFrameByType("BACKDROP", "BackdropButtonCh01", ButtonCh01, "", 0)
BlzFrameSetAllPoints(BackdropButtonCh01, ButtonCh01)
BlzFrameSetTexture(BackdropButtonCh01, "ReplaceableTextures\\CommandButtons\\BTNHumanLumberMill.blp", 0, true)
TriggerButtonCh01 = CreateTrigger() 
BlzTriggerRegisterFrameEvent(TriggerButtonCh01, ButtonCh01, FRAMEEVENT_CONTROL_CLICK) 
TriggerAddAction(TriggerButtonCh01, ProjectSurvive.ButtonCh01Func) 

ButtonCh02 = BlzCreateFrame("IconButtonTemplate", WindowChapterSelect, 0, 0)
BlzFrameSetAbsPoint(ButtonCh02, FRAMEPOINT_TOPLEFT, 0.385000, 0.345000)
BlzFrameSetAbsPoint(ButtonCh02, FRAMEPOINT_BOTTOMRIGHT, 0.415000, 0.315000)

BackdropButtonCh02 = BlzCreateFrameByType("BACKDROP", "BackdropButtonCh02", ButtonCh02, "", 0)
BlzFrameSetAllPoints(BackdropButtonCh02, ButtonCh02)
BlzFrameSetTexture(BackdropButtonCh02, "BTNChapterDF.blp", 0, true)
TriggerButtonCh02 = CreateTrigger() 
BlzTriggerRegisterFrameEvent(TriggerButtonCh02, ButtonCh02, FRAMEEVENT_CONTROL_CLICK) 
TriggerAddAction(TriggerButtonCh02, ProjectSurvive.ButtonCh02Func) 

ButtonCh03 = BlzCreateFrame("IconButtonTemplate", WindowChapterSelect, 0, 0)
BlzFrameSetAbsPoint(ButtonCh03, FRAMEPOINT_TOPLEFT, 0.425000, 0.345000)
BlzFrameSetAbsPoint(ButtonCh03, FRAMEPOINT_BOTTOMRIGHT, 0.455000, 0.315000)

BackdropButtonCh03 = BlzCreateFrameByType("BACKDROP", "BackdropButtonCh03", ButtonCh03, "", 0)
BlzFrameSetAllPoints(BackdropButtonCh03, ButtonCh03)
BlzFrameSetTexture(BackdropButtonCh03, "BTNChapterMekanika.blp", 0, true)
TriggerButtonCh03 = CreateTrigger() 
BlzTriggerRegisterFrameEvent(TriggerButtonCh03, ButtonCh03, FRAMEEVENT_CONTROL_CLICK) 
TriggerAddAction(TriggerButtonCh03, ProjectSurvive.ButtonCh03Func) 

TooltipPrologue = BlzCreateFrame("CheckListBox", ButtonCh01, 0, 0)
BlzFrameSetAbsPoint(TooltipPrologue, FRAMEPOINT_TOPLEFT, 0.505000, 0.400930)
BlzFrameSetAbsPoint(TooltipPrologue, FRAMEPOINT_BOTTOMRIGHT, 0.710000, 0.300930)

BlzFrameSetTooltip(ButtonCh01, TooltipPrologue)

TooltipDF = BlzCreateFrame("CheckListBox", ButtonCh02, 0, 0)
BlzFrameSetAbsPoint(TooltipDF, FRAMEPOINT_TOPLEFT, 0.505000, 0.400930)
BlzFrameSetAbsPoint(TooltipDF, FRAMEPOINT_BOTTOMRIGHT, 0.710000, 0.300930)

BlzFrameSetTooltip(ButtonCh02, TooltipDF)

TooltipMekanika = BlzCreateFrame("CheckListBox", ButtonCh03, 0, 0)
BlzFrameSetAbsPoint(TooltipMekanika, FRAMEPOINT_TOPLEFT, 0.505000, 0.400930)
BlzFrameSetAbsPoint(TooltipMekanika, FRAMEPOINT_BOTTOMRIGHT, 0.710000, 0.300930)

BlzFrameSetTooltip(ButtonCh03, TooltipMekanika)

TooltipPrologueText = BlzCreateFrameByType("TEXT", "name", TooltipPrologue, "", 0)
BlzFrameSetAbsPoint(TooltipPrologueText, FRAMEPOINT_TOPLEFT, 0.523130, 0.388980)
BlzFrameSetAbsPoint(TooltipPrologueText, FRAMEPOINT_BOTTOMRIGHT, 0.613130, 0.334980)
BlzFrameSetText(TooltipPrologueText, "|cffffffffPrologue\n\n|cffffcc00Tutorial|r\n\nDifficulty: |cff44ff44Easy|r|r")
BlzFrameSetEnable(TooltipPrologueText, false)
BlzFrameSetScale(TooltipPrologueText, 1.00)
BlzFrameSetTextAlignment(TooltipPrologueText, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)

TooltipDFText = BlzCreateFrameByType("TEXT", "name", TooltipDF, "", 0)
BlzFrameSetAbsPoint(TooltipDFText, FRAMEPOINT_TOPLEFT, 0.523130, 0.388980)
BlzFrameSetAbsPoint(TooltipDFText, FRAMEPOINT_BOTTOMRIGHT, 0.613130, 0.334980)
BlzFrameSetText(TooltipDFText, "|cffffffffDecaying Forest\n\n|cffffcc00Work-in-Progress|r\n\n|cffff4444Not Available yet|r|r")
BlzFrameSetEnable(TooltipDFText, false)
BlzFrameSetScale(TooltipDFText, 1.00)
BlzFrameSetTextAlignment(TooltipDFText, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)

TooltipMekanikaText = BlzCreateFrameByType("TEXT", "name", TooltipMekanika, "", 0)
BlzFrameSetAbsPoint(TooltipMekanikaText, FRAMEPOINT_TOPLEFT, 0.523130, 0.388980)
BlzFrameSetAbsPoint(TooltipMekanikaText, FRAMEPOINT_BOTTOMRIGHT, 0.613130, 0.334980)
BlzFrameSetText(TooltipMekanikaText, "|cffffffffMekanika Isles\n\n|cffff4444Not Available yet|r|r")
BlzFrameSetEnable(TooltipMekanikaText, false)
BlzFrameSetScale(TooltipMekanikaText, 1.00)
BlzFrameSetTextAlignment(TooltipMekanikaText, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)
end
