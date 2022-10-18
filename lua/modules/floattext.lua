-- based on AnonymousPro@hivework.com work: 
-- https://www.hiveworkshop.com/threads/how-to-create-text-tags-in-jass-at-different-points-on-the-map.288337/
local MEAN_CHAR_WIDTH = 5.5
local MAX_TEXT_SHIFT = 200.0
-- module
Module("FloatText",
{
    White = {255,255,255,255},
    Blue = {40, 40, 240, 255 },
    Green = {60, 240, 60, 255},
    Blue = {70,134,240, 255},
    Red = {220, 40, 40, 255},

    Create = function(unit --[[unit handle]], message --[[string]], duration --[[number]], color --[[array<number:4>]], playeronly --[[playerhandle or boolean true -> owner, false -> everyone]])
        local txt = CreateTextTag()
        local permanent = duration == nil or duration <= 0
        local shift = math.min(string.len(message) * MEAN_CHAR_WIDTH, MAX_TEXT_SHIFT)
        local visible = true
        color = color or FloatText.White

        if playeronly == true then
            visible = GetLocalPlayer() == GetOwningPlayer(unit)
        elseif playeronly ~= nil then
            visible = GetLocalPlayer() == playeronly
        end

        SetTextTagPos(txt, GetUnitX(unit) - shift, GetUnitY(unit) + 50.0, 5.0)
        SetTextTagColor(txt, color[1], color[2], color[3], color[4])
        SetTextTagText(txt, message, 0.024)
        SetTextTagVisibility(txt, visible) -- playeronly == nil or GetLocalPlayer() == playeronly)
        SetTextTagPermanent(txt, permanent)

        if not permanent then
            SetTextTagVelocity(txt, 0.0, 0.04)
            SetTextTagLifespan(txt, duration)
            SetTextTagFadepoint(txt, duration * 2.0 / 3.0)
            Clock.DelayedCallback(function() DestroyTextTag(txt) end, duration + 1.0)
        end
    end
})

