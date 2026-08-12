Skin = Skin or {}

local const = Skin.const

local clothing = {}
Skin.clothing = clothing

-- GTA records which arms / undershirt belong to a given top in SHOP_CLOTHES.meta
-- (forcedComponentList). That is the same data the in-game clothing store uses
-- to avoid clipping, and it is readable at runtime - so there is no hand-curated
-- rule set here, and DLC updates keep working without changes.
--
-- Caveat: this only exists for actual shop items. Job outfits and most addon
-- clothing return a hash of 0, in which case nothing happens.

local function supported()
    return Skin.hasNative("GetHashNameForComponent")
        and Skin.hasNative("GetShopPedApparelForcedComponentCount")
        and Skin.hasNative("GetForcedComponent")
end

--- The unique shop item hash for a component slot, or 0 when it is not a shop
--- item (job outfit, addon clothing, placeholder drawable).
function clothing.itemHash(ped, name, slot)
    local componentId = const.COMPONENTS[name]
    if not componentId or not Skin.hasNative("GetHashNameForComponent") then return 0 end

    -- The shop natives speak global indices.
    local global = Skin.collections.toGlobalDrawable(ped, componentId, slot.collection, slot.drawable)
    if not global or global < 0 then return 0 end

    return GetHashNameForComponent(ped, componentId, global, slot.texture) or 0
end

function clothing.propItemHash(ped, name, slot)
    local anchor = const.PROPS[name]
    if not anchor or slot.drawable < 0 or not Skin.hasNative("GetHashNameForProp") then return 0 end

    local global = Skin.collections.toGlobalProp(ped, anchor, slot.collection, slot.drawable)
    if not global or global < 0 then return 0 end

    return GetHashNameForProp(ped, anchor, global, slot.texture) or 0
end

--- Turns a raw forced/variant entry into a schema slot.
--- `enumValue` is a GLOBAL drawable index - converting it back to
--- collection + local index here is what keeps the stored appearance stable
--- across title updates.
local function toSlot(ped, componentType, enumValue)
    local name = const.COMPONENT_NAMES[componentType]
    if not name or not enumValue or enumValue < 0 then return nil end

    local collection, localIndex = Skin.collections.fromGlobalDrawable(ped, componentType, enumValue)

    return {
        component = name,
        collection = collection,
        drawable = localIndex,
        texture = 0
    }
end

local function toPropSlot(ped, anchor, enumValue)
    local name = const.PROP_NAMES[anchor]
    if not name or not enumValue then return nil end

    if enumValue < 0 then
        return { prop = name, collection = const.BASE_COLLECTION, drawable = -1, texture = 0 }
    end

    local collection, localIndex = Skin.collections.fromGlobalProp(ped, anchor, enumValue)

    return {
        prop = name,
        collection = collection,
        drawable = localIndex,
        texture = 0
    }
end

--- Components this item forces onto other slots, e.g. a suit jacket forcing the
--- matching arms and undershirt.
--- @return table[] list of { component, collection, drawable, texture }
function clothing.forcedComponents(ped, name, slot)
    local out = {}
    if not supported() then return out end

    local hash = clothing.itemHash(ped, name, slot)
    if hash == 0 then
        -- Not a shop item - fall back to the manual override table, if any.
        local key = ("%s:%s:%d"):format(name, slot.collection or "", slot.drawable)
        local override = Config.Clothing.forcedOverrides[key]

        if override then
            for i = 1, #override do out[#out + 1] = override[i] end
        end

        return out
    end

    local count = GetShopPedApparelForcedComponentCount(hash) or 0
    for i = 0, count - 1 do
        local _, enumValue, componentType = GetForcedComponent(hash, i)
        local resolved = toSlot(ped, componentType, enumValue)
        if resolved then out[#out + 1] = resolved end
    end

    return out
end

function clothing.forcedProps(ped, name, slot)
    local out = {}
    if not Skin.hasNative("GetShopPedApparelForcedPropCount") or not Skin.hasNative("GetForcedProp") then
        return out
    end

    local hash = clothing.itemHash(ped, name, slot)
    if hash == 0 then return out end

    local count = GetShopPedApparelForcedPropCount(hash) or 0
    for i = 0, count - 1 do
        local _, enumValue, anchor = GetForcedProp(hash, i)
        local resolved = toPropSlot(ped, anchor, enumValue)
        if resolved then out[#out + 1] = resolved end
    end

    return out
end

--- Non-clipping alternative versions of other slots that go with this item.
function clothing.variants(ped, name, slot)
    local out = {}
    if not Skin.hasNative("GetShopPedApparelVariantComponentCount") or not Skin.hasNative("GetVariantComponent") then
        return out
    end

    local hash = clothing.itemHash(ped, name, slot)
    if hash == 0 then return out end

    local count = GetShopPedApparelVariantComponentCount(hash) or 0
    for i = 0, count - 1 do
        local _, enumValue, componentType = GetVariantComponent(hash, i)
        local resolved = toSlot(ped, componentType, enumValue)
        if resolved then out[#out + 1] = resolved end
    end

    return out
end

--- Expands a component set with everything GTA says has to come with it.
---
--- Explicitly supplied slots win: whoever passes both `torso` and `arms` gets
--- their arms. Only slots that were NOT supplied get filled from the forced
--- data - otherwise you could never deliberately deviate (job uniforms, RP).
---
--- @param ped number
--- @param components table name -> slot, the desired set
--- @param explicit table|nil name -> true, slots the caller set on purpose
--- @return table components, table props
function clothing.resolve(ped, components, explicit)
    explicit = explicit or {}

    local outComponents = Skin.path.copy(components)
    local outProps = {}

    if not Config.Clothing.applyForcedComponents and not Config.Clothing.applyForcedProps then
        return outComponents, outProps
    end

    -- Tops drive the dependency, so process them last: their forced values must
    -- win over anything an earlier item asked for.
    local order = { "pants", "shoes", "shirt", "armor", "torso" }
    local seen = {}
    for i = 1, #order do seen[order[i]] = true end
    for name in pairs(components) do
        if not seen[name] then order[#order + 1] = name end
    end

    for i = 1, #order do
        local name = order[i]
        local slot = components[name]

        if slot then
            if Config.Clothing.applyForcedComponents then
                local forced = clothing.forcedComponents(ped, name, slot)

                for j = 1, #forced do
                    local entry = forced[j]

                    if entry.component ~= name and not explicit[entry.component] then
                        outComponents[entry.component] = {
                            collection = entry.collection,
                            drawable = entry.drawable,
                            texture = entry.texture,
                            palette = 0
                        }
                        Skin.log(("forced %s -> %s/%d (from %s)"):format(
                            entry.component, entry.collection, entry.drawable, name))
                    end
                end

                -- Variants are the softer option: keep the slot but swap it for
                -- the version that does not clip with this item.
                if Config.Clothing.preferVariants then
                    local variants = clothing.variants(ped, name, slot)

                    for j = 1, #variants do
                        local entry = variants[j]
                        if entry.component ~= name and not explicit[entry.component] and not outComponents[entry.component] then
                            outComponents[entry.component] = {
                                collection = entry.collection,
                                drawable = entry.drawable,
                                texture = entry.texture,
                                palette = 0
                            }
                        end
                    end
                end
            end

            if Config.Clothing.applyForcedProps then
                local forced = clothing.forcedProps(ped, name, slot)
                for j = 1, #forced do
                    local entry = forced[j]
                    outProps[entry.prop] = {
                        collection = entry.collection,
                        drawable = entry.drawable,
                        texture = entry.texture
                    }
                end
            end
        end
    end

    return outComponents, outProps
end
