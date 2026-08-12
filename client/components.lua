Appearance = Appearance or {}

local const = Appearance.const

local components = {}
Appearance.components = components

--- Resolves legacy slots (no collection given -> the drawable is a global
--- index) into collection + local index. Needs a real ped, which is why this
--- cannot live in shared/schema.lua.
function components.resolveLegacy(ped, appearance)
    for name, slot in pairs(appearance.components) do
        if slot.legacy then
            local componentId = const.COMPONENTS[name]
            if componentId then
                slot.collection, slot.drawable = Appearance.collections.fromGlobalDrawable(ped, componentId, slot.drawable)
            end
            slot.legacy = nil
        end
    end

    for name, slot in pairs(appearance.props) do
        if slot.legacy then
            local anchor = const.PROPS[name]
            if anchor then
                slot.collection, slot.drawable = Appearance.collections.fromGlobalProp(ped, anchor, slot.drawable)
            end
            slot.legacy = nil
        end
    end

    if appearance.hair.legacy then
        appearance.hair.collection, appearance.hair.drawable =
            Appearance.collections.fromGlobalDrawable(ped, const.COMPONENT_HAIR, appearance.hair.drawable)
        appearance.hair.legacy = nil
    end

    return appearance
end

--- Writes a single component slot. Validation happens first because the set
--- native fails silently on invalid indices.
--- @return boolean ok, string|nil reason
function components.applyComponent(ped, name, slot)
    local componentId = const.COMPONENTS[name]
    if not componentId then return false, "unknown component" end

    local validated, reason = Appearance.collections.validateComponent(ped, name, slot)
    if not validated then return false, reason end

    SetPedCollectionComponentVariation(
        ped,
        componentId,
        validated.collection,
        validated.drawable,
        validated.texture,
        validated.palette or 0
    )

    -- Hand the corrected values back so the cache stores what is actually worn.
    slot.collection = validated.collection
    slot.drawable = validated.drawable
    slot.texture = validated.texture
    slot.palette = validated.palette or 0

    return true
end

function components.applyProp(ped, name, slot)
    local anchor = const.PROPS[name]
    if not anchor then return false, "unknown prop" end

    local validated, reason = Appearance.collections.validateProp(ped, name, slot)
    if not validated then return false, reason end

    if validated.drawable < 0 then
        ClearPedProp(ped, anchor)
    else
        SetPedCollectionPropIndex(
            ped,
            anchor,
            validated.collection,
            validated.drawable,
            validated.texture,
            true
        )
    end

    slot.collection = validated.collection
    slot.drawable = validated.drawable
    slot.texture = validated.texture

    return true
end

--- Applies every component and prop, expanding the set with GTA's forced
--- components first so arms/undershirt match the top.
--- @param explicit table|nil slots the caller set on purpose (win over forced)
function components.applyAll(ped, appearance, explicit)
    local resolved, forcedProps = Appearance.clothing.resolve(ped, appearance.components, explicit)

    for name, slot in pairs(resolved) do
        appearance.components[name] = slot
    end

    -- Forced props only fill slots the caller did not set.
    for name, slot in pairs(forcedProps) do
        if not (explicit and explicit[name]) then
            appearance.props[name] = slot
        end
    end

    -- In "reject" mode nothing may be applied unless everything validates.
    -- Otherwise a refused value would still leave the ped half-changed, and the
    -- caller would get no way to tell.
    if Config.Validation == "reject" then
        for name, slot in pairs(appearance.components) do
            local ok, reason = Appearance.collections.validateComponent(ped, name, slot)
            if not ok then return false, ("component '%s': %s"):format(name, reason or "invalid") end
        end

        for name, slot in pairs(appearance.props) do
            local ok, reason = Appearance.collections.validateProp(ped, name, slot)
            if not ok then return false, ("prop '%s': %s"):format(name, reason or "invalid") end
        end
    end

    for name, slot in pairs(appearance.components) do
        local ok, reason = components.applyComponent(ped, name, slot)
        if not ok then
            -- clamp could not rescue this one (no valid texture at all, or a
            -- missing collection with FallbackToNaked off).
            return false, ("component '%s': %s"):format(name, reason or "invalid")
        end
    end

    for name, slot in pairs(appearance.props) do
        local ok, reason = components.applyProp(ped, name, slot)
        if not ok then
            return false, ("prop '%s': %s"):format(name, reason or "invalid")
        end
    end

    return true
end
