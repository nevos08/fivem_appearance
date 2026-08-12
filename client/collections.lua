Skin = Skin or {}

local const = Skin.const

local collections = {}
Skin.collections = collections

--- Every collection name available on the ped, in game order.
--- @return string[]
function collections.list(ped)
    local out = {}
    local count = GetPedCollectionsCount(ped)

    for i = 0, count - 1 do
        out[#out + 1] = GetPedCollectionName(ped, i)
    end

    return out
end

--- Whether a collection exists on this ped at all. Addon clothing that is not
--- streamed, or a missing DLC, shows up here.
function collections.exists(ped, collection)
    if collection == nil or collection == const.BASE_COLLECTION then return true end

    local count = GetPedCollectionsCount(ped)
    for i = 0, count - 1 do
        if GetPedCollectionName(ped, i) == collection then return true end
    end

    return false
end

-----------------------------------------------------------------------------
-- Global <-> collection-local index conversion
-----------------------------------------------------------------------------

--- Converts a legacy global drawable index into collection + local index.
--- @return string collection, number localDrawable
function collections.fromGlobalDrawable(ped, componentId, globalDrawable)
    local collection = GetPedCollectionNameFromDrawable(ped, componentId, globalDrawable)
    local localIndex = GetPedCollectionLocalIndexFromDrawable(ped, componentId, globalDrawable)

    if collection == nil or localIndex == nil or localIndex < 0 then
        -- Out of range: treat it as base game and let validation clamp it.
        return const.BASE_COLLECTION, globalDrawable
    end

    return collection, localIndex
end

function collections.fromGlobalProp(ped, anchor, globalDrawable)
    if globalDrawable < 0 then return const.BASE_COLLECTION, -1 end

    local collection = GetPedCollectionNameFromProp(ped, anchor, globalDrawable)
    local localIndex = GetPedCollectionLocalIndexFromProp(ped, anchor, globalDrawable)

    if collection == nil or localIndex == nil or localIndex < 0 then
        return const.BASE_COLLECTION, globalDrawable
    end

    return collection, localIndex
end

--- Converts collection + local index back to a global index, for interop with
--- resources that still speak the old language (esx_clotheshop and friends).
function collections.toGlobalDrawable(ped, componentId, collection, localDrawable)
    return GetPedDrawableGlobalIndexFromCollection(ped, componentId, collection or const.BASE_COLLECTION, localDrawable)
end

function collections.toGlobalProp(ped, anchor, collection, localDrawable)
    if localDrawable < 0 then return -1 end
    return GetPedPropGlobalIndexFromCollection(ped, anchor, collection or const.BASE_COLLECTION, localDrawable)
end

-----------------------------------------------------------------------------
-- Variation counts
-----------------------------------------------------------------------------

--- @return number drawables, number textures for the given drawable
function collections.componentCounts(ped, componentId, collection, drawable)
    collection = collection or const.BASE_COLLECTION

    local drawables = GetNumberOfPedCollectionDrawableVariations(ped, componentId, collection) or 0
    local textures = 0

    if drawable and drawable >= 0 and drawable < drawables then
        textures = GetNumberOfPedCollectionTextureVariations(ped, componentId, collection, drawable) or 0
    end

    return drawables, textures
end

function collections.propCounts(ped, anchor, collection, drawable)
    collection = collection or const.BASE_COLLECTION

    local drawables = GetNumberOfPedCollectionPropDrawableVariations(ped, anchor, collection) or 0
    local textures = 0

    if drawable and drawable >= 0 and drawable < drawables then
        textures = GetNumberOfPedCollectionPropTextureVariations(ped, anchor, collection, drawable) or 0
    end

    return drawables, textures
end

-----------------------------------------------------------------------------
-- Validation
-----------------------------------------------------------------------------

--- Validates and, depending on Config.Validation, clamps a component slot.
--- The set natives fail SILENTLY on invalid indices, which leaves an invisible
--- ped with no error - so nothing gets applied without passing through here.
---
--- @return table|nil slot the (possibly clamped) slot, nil when rejected
--- @return string|nil reason
function collections.validateComponent(ped, name, slot)
    local componentId = const.COMPONENTS[name]
    if not componentId then return nil, "unknown component" end

    local mode = Config.Validation
    if mode == "off" then return slot end

    local collection = slot.collection or const.BASE_COLLECTION

    if not collections.exists(ped, collection) then
        if not Config.FallbackToNaked then
            return nil, ("collection '%s' not present on ped"):format(collection)
        end

        local sex = Skin.schema.sexOf(GetEntityModel(ped)) or "male"
        local naked = const.NAKED[sex] and const.NAKED[sex][name]

        Skin.log(("collection '%s' missing for '%s', falling back to naked"):format(collection, name))

        return {
            collection = const.BASE_COLLECTION,
            drawable = naked and naked.drawable or 0,
            texture = naked and naked.texture or 0,
            palette = slot.palette or 0
        }
    end

    local drawables, _ = collections.componentCounts(ped, componentId, collection)
    if drawables <= 0 then
        return nil, ("no drawables for component '%s' in collection '%s'"):format(name, collection)
    end

    local drawable = slot.drawable
    if drawable < 0 or drawable >= drawables then
        if mode == "reject" then
            return nil, ("drawable %d out of range (0-%d) for '%s'"):format(drawable, drawables - 1, name)
        end
        drawable = math.max(0, math.min(drawable, drawables - 1))
        Skin.log(("clamped %s drawable %d -> %d"):format(name, slot.drawable, drawable))
    end

    local _, textures = collections.componentCounts(ped, componentId, collection, drawable)
    local texture = slot.texture

    if texture < 0 or texture >= math.max(textures, 1) then
        if mode == "reject" then
            return nil, ("texture %d out of range (0-%d) for '%s'"):format(texture, math.max(textures - 1, 0), name)
        end
        texture = math.max(0, math.min(texture, math.max(textures - 1, 0)))
    end

    if not IsPedCollectionComponentVariationValid(ped, componentId, collection, drawable, texture) then
        if mode == "reject" then
            return nil, ("invalid variation %s/%s/%d/%d"):format(name, collection, drawable, texture)
        end

        -- Walk textures for a valid one before giving up on the drawable.
        local found
        for t = 0, math.max(textures - 1, 0) do
            if IsPedCollectionComponentVariationValid(ped, componentId, collection, drawable, t) then
                found = t
                break
            end
        end

        if not found then
            return nil, ("no valid texture for %s/%s/%d"):format(name, collection, drawable)
        end
        texture = found
    end

    if Config.Debug and Skin.hasNative("IsPedCollectionComponentVariationGen9Exclusive") then
        if IsPedCollectionComponentVariationGen9Exclusive(ped, componentId, collection, drawable) then
            Skin.log(("'%s' %s/%d is Gen9-exclusive and may not render for every client"):format(name, collection, drawable))
        end
    end

    return {
        collection = collection,
        drawable = drawable,
        texture = texture,
        palette = slot.palette or 0
    }
end

function collections.validateProp(ped, name, slot)
    local anchor = const.PROPS[name]
    if not anchor then return nil, "unknown prop" end

    -- -1 means "no prop" and is always valid.
    if slot.drawable < 0 then
        return { collection = const.BASE_COLLECTION, drawable = -1, texture = 0 }
    end

    local mode = Config.Validation
    if mode == "off" then return slot end

    local collection = slot.collection or const.BASE_COLLECTION

    if not collections.exists(ped, collection) then
        if mode == "reject" then
            return nil, ("collection '%s' not present on ped"):format(collection)
        end
        return { collection = const.BASE_COLLECTION, drawable = -1, texture = 0 }
    end

    local drawables = collections.propCounts(ped, anchor, collection)
    if drawables <= 0 then
        return { collection = const.BASE_COLLECTION, drawable = -1, texture = 0 }
    end

    local drawable = slot.drawable
    if drawable >= drawables then
        if mode == "reject" then
            return nil, ("prop drawable %d out of range (0-%d) for '%s'"):format(drawable, drawables - 1, name)
        end
        drawable = drawables - 1
    end

    local _, textures = collections.propCounts(ped, anchor, collection, drawable)
    local texture = slot.texture

    if texture < 0 or texture >= math.max(textures, 1) then
        if mode == "reject" then
            return nil, ("prop texture %d out of range for '%s'"):format(texture, name)
        end
        texture = math.max(0, math.min(texture, math.max(textures - 1, 0)))
    end

    return { collection = collection, drawable = drawable, texture = texture }
end
