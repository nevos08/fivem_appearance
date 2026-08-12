Skin = Skin or {}

local const = Skin.const

local hair = {}
Skin.hair = hair

--- The hair fade / dip is not part of the hair component - it is a ped
--- decoration on the torso. That means it shares a slot with the tattoos and
--- gets wiped by ClearPedDecorations, which is why applying it lives in the
--- decoration step of the pipeline rather than here.
---
--- @return table|false|nil { collection, overlay }, false when explicitly off
function hair.resolveFade(model, hairData)
    if hairData.fade == false then return false end
    if type(hairData.fade) == "table" then return hairData.fade end

    -- No explicit fade: fall back to the style's default from the lookup table.
    local sex = Skin.schema.sexOf(model)
    if not sex then return nil end

    local entry = const.HAIR_DECORATIONS[sex] and const.HAIR_DECORATIONS[sex][hairData.drawable]
    if not entry then return nil end

    return { collection = entry[1], overlay = entry[2] }
end

--- Applies the hair component and colour. The fade is handled by the decoration
--- step, but is resolved here so hair and fade always travel together.
function hair.apply(ped, hairData)
    SetPedCollectionComponentVariation(
        ped,
        const.COMPONENT_HAIR,
        hairData.collection or const.BASE_COLLECTION,
        hairData.drawable,
        hairData.texture,
        0
    )

    SetPedHairColor(ped, hairData.color, hairData.highlight)
end

--- Validates a hair slot the same way clothing components are validated.
function hair.validate(ped, hairData)
    local mode = Config.Validation
    if mode == "off" then return hairData end

    local collection = hairData.collection or const.BASE_COLLECTION

    if not Skin.collections.exists(ped, collection) then
        collection = const.BASE_COLLECTION
    end

    local drawables, _ = Skin.collections.componentCounts(ped, const.COMPONENT_HAIR, collection)
    local drawable = hairData.drawable

    if drawables > 0 and (drawable < 0 or drawable >= drawables) then
        if mode == "reject" then
            return nil, ("hair drawable %d out of range (0-%d)"):format(drawable, drawables - 1)
        end
        drawable = math.max(0, math.min(drawable, drawables - 1))
    end

    local _, textures = Skin.collections.componentCounts(ped, const.COMPONENT_HAIR, collection, drawable)
    local texture = hairData.texture

    if texture < 0 or texture >= math.max(textures, 1) then
        if mode == "reject" then
            return nil, ("hair texture %d out of range"):format(texture)
        end
        texture = math.max(0, math.min(texture, math.max(textures - 1, 0)))
    end

    return {
        collection = collection,
        drawable = drawable,
        texture = texture,
        color = hairData.color,
        highlight = hairData.highlight,
        fade = hairData.fade
    }
end
