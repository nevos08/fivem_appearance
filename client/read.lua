Skin = Skin or {}

local const = Skin.const

--- Reads an appearance back off a ped using the natives.
---
--- Decorations are NOT readable - there is no native that enumerates them. So
--- tattoos and the hair fade can only come from the cache, and the result is
--- flagged `partial` to stop callers from silently persisting an empty tattoo
--- list over a good one.
---
--- @return table appearance, boolean partial
function Skin.read(ped)
    ped = ped or PlayerPedId()

    local model = GetEntityModel(ped)
    local sex = Skin.schema.sexOf(model)
    local out = Skin.schema.default(sex)

    out.model = model

    -- Components ------------------------------------------------------------
    for name, componentId in pairs(const.COMPONENTS) do
        out.components[name] = {
            collection = GetPedDrawableVariationCollectionName(ped, componentId) or const.BASE_COLLECTION,
            drawable = GetPedDrawableVariationCollectionLocalIndex(ped, componentId) or 0,
            texture = GetPedTextureVariation(ped, componentId) or 0,
            palette = GetPedPaletteVariation(ped, componentId) or 0
        }
    end

    -- Props -----------------------------------------------------------------
    for name, anchor in pairs(const.PROPS) do
        local drawable = GetPedPropIndex(ped, anchor)

        if drawable == nil or drawable < 0 then
            out.props[name] = { collection = const.BASE_COLLECTION, drawable = -1, texture = 0 }
        else
            out.props[name] = {
                collection = GetPedPropCollectionName(ped, anchor) or const.BASE_COLLECTION,
                drawable = GetPedPropCollectionLocalIndex(ped, anchor) or 0,
                texture = GetPedPropTextureIndex(ped, anchor) or 0
            }
        end
    end

    -- Hair ------------------------------------------------------------------
    out.hair.collection = GetPedDrawableVariationCollectionName(ped, const.COMPONENT_HAIR) or const.BASE_COLLECTION
    out.hair.drawable = GetPedDrawableVariationCollectionLocalIndex(ped, const.COMPONENT_HAIR) or 0
    out.hair.texture = GetPedTextureVariation(ped, const.COMPONENT_HAIR) or 0

    if Skin.hasNative("GetPedHairColor") then
        out.hair.color = GetPedHairColor(ped) or 0
    end
    if Skin.hasNative("GetPedHairHighlightColor") then
        out.hair.highlight = GetPedHairHighlightColor(ped) or 0
    end

    if sex then
        -- Head blend ---------------------------------------------------------
        if Skin.hasNative("GetPedHeadBlendData") then
            local blend = GetPedHeadBlendData(ped)
            if type(blend) == "table" then
                out.headBlend.shapeFirst = blend.shapeFirst or out.headBlend.shapeFirst
                out.headBlend.shapeSecond = blend.shapeSecond or out.headBlend.shapeSecond
                out.headBlend.skinFirst = blend.skinFirst or out.headBlend.skinFirst
                out.headBlend.skinSecond = blend.skinSecond or out.headBlend.skinSecond
                out.headBlend.shapeMix = blend.shapeMix or out.headBlend.shapeMix
                out.headBlend.skinMix = blend.skinMix or out.headBlend.skinMix
            end
        end

        -- Face features ------------------------------------------------------
        if Skin.hasNative("GetPedFaceFeature") then
            for i = 1, #const.FACE_FEATURES do
                out.faceFeatures[const.FACE_FEATURES[i]] = GetPedFaceFeature(ped, i - 1) or 0.0
            end
        end

        -- Head overlays ------------------------------------------------------
        if Skin.hasNative("GetPedHeadOverlayData") then
            for i = 1, #const.HEAD_OVERLAYS do
                local name = const.HEAD_OVERLAYS[i]
                local ok, style, colorType, color, secondColor, opacity = GetPedHeadOverlayData(ped, i - 1)

                if ok then
                    out.headOverlays[name] = {
                        style = style or const.OVERLAY_NONE,
                        opacity = opacity or 0.0,
                        colorType = colorType or const.OVERLAY_COLOR_TYPE[name] or 0,
                        color = color or 0,
                        secondColor = secondColor or 0
                    }
                end
            end
        end

        if Skin.hasNative("GetPedEyeColor") then
            out.eyeColor = GetPedEyeColor(ped) or 0
        end
    end

    -- Decorations are not readable - carry them over from the cache instead.
    local cached = Skin.client.current
    if cached then
        out.tattoos = Skin.path.copy(cached.tattoos)
        out.hair.fade = Skin.path.copy(cached.hair.fade)
        return out, false
    end

    return out, true
end
