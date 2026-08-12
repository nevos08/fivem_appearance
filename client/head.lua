Appearance = Appearance or {}

local const = Appearance.const

local head = {}
Appearance.head = head

--- Head blend. Must run before the overlays, otherwise they do not take on a
--- freemode ped.
---
--- The third parent slots are deliberately fixed at 0 / 0.0 - a third parent is
--- not part of this schema. The skin fields are written as stored; the
--- Config.HeadBlend coupling already happened in schema.normalize().
function head.applyBlend(ped, blend)
    SetPedHeadBlendData(
        ped,
        blend.shapeFirst, blend.shapeSecond, 0,
        blend.skinFirst, blend.skinSecond, 0,
        blend.shapeMix + 0.0, blend.skinMix + 0.0, 0.0,
        false
    )
end

function head.applyFeatures(ped, features)
    for i = 1, #const.FACE_FEATURES do
        local name = const.FACE_FEATURES[i]
        local value = features[name]

        if value then
            SetPedFaceFeature(ped, i - 1, value + 0.0)
        end
    end
end

function head.applyOverlay(ped, name, overlay)
    local index = const.HEAD_OVERLAY_INDEX[name]
    if not index then return end

    -- 255 is "no overlay". Opacity is a float 0.0 - 1.0.
    SetPedHeadOverlay(ped, index, overlay.style, overlay.opacity + 0.0)

    local colorType = overlay.colorType or const.OVERLAY_COLOR_TYPE[name] or 0
    if colorType ~= 0 then
        SetPedHeadOverlayColor(ped, index, colorType, overlay.color, overlay.secondColor)
    end
end

function head.applyOverlays(ped, overlays)
    for i = 1, #const.HEAD_OVERLAYS do
        local name = const.HEAD_OVERLAYS[i]
        local overlay = overlays[name]

        if overlay then
            head.applyOverlay(ped, name, overlay)
        end
    end
end

function head.applyEyeColor(ped, eyeColor)
    SetPedEyeColor(ped, eyeColor)
end
