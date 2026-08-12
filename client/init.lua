Skin = Skin or {}

Skin.client = {
    -- Last appearance applied to the local ped. Getters read from here first.
    current = nil,
    -- Guards against overlapping Apply calls (model loading yields).
    busy = false
}

local RESOURCE = GetCurrentResourceName()

function Skin.log(...)
    if not Config.Debug then return end
    print(("[%s]"):format(RESOURCE), ...)
end

function Skin.warn(...)
    print(("[%s] ^3WARN^7"):format(RESOURCE), ...)
end

function Skin.err(...)
    print(("[%s] ^1ERROR^7"):format(RESOURCE), ...)
end

--- Not every native in this resource exists on every game build or FiveM
--- version - the shop apparel ones in particular are untyped natives whose
--- aliases have changed. Features guard on this instead of hard-crashing.
local nativeCache = {}
function Skin.hasNative(name)
    local cached = nativeCache[name]
    if cached ~= nil then return cached end

    local ok = type(_G[name]) == "function"
    nativeCache[name] = ok

    if not ok then
        Skin.warn(("native '%s' is unavailable on this build - related features are disabled"):format(name))
    end

    return ok
end

--- Resolves "torso" / 11 to both the canonical name and the component id.
--- @return string|nil name, number|nil id
function Skin.resolveComponent(nameOrId)
    local const = Skin.const

    if type(nameOrId) == "string" then
        local id = const.COMPONENTS[nameOrId]
        if id then return nameOrId, id end
        nameOrId = tonumber(nameOrId)
    end

    if type(nameOrId) == "number" then
        local name = const.COMPONENT_NAMES[nameOrId]
        if name then return name, nameOrId end
    end

    return nil, nil
end

--- Like resolveComponent, but also accepts "hair" (component 2).
---
--- Hair is not a clothing component in the schema - it has its own subsystem
--- because the fade travels with it - but for variation counts, validity and
--- index conversion it behaves like any other component, and a creator needs to
--- be able to enumerate it.
function Skin.resolveVariationTarget(nameOrId)
    if nameOrId == "hair" or nameOrId == Skin.const.COMPONENT_HAIR then
        return "hair", Skin.const.COMPONENT_HAIR
    end

    return Skin.resolveComponent(nameOrId)
end

--- Resolves "hats" / 0 to both the canonical name and the anchor point.
function Skin.resolveProp(nameOrId)
    local const = Skin.const

    if type(nameOrId) == "string" then
        local id = const.PROPS[nameOrId]
        if id then return nameOrId, id end
        nameOrId = tonumber(nameOrId)
    end

    if type(nameOrId) == "number" then
        local name = const.PROP_NAMES[nameOrId]
        if name then return name, nameOrId end
    end

    return nil, nil
end

--- Resolves "beard" / 1 to both the overlay name and its index.
function Skin.resolveOverlay(nameOrId)
    local const = Skin.const

    if type(nameOrId) == "string" then
        local index = const.HEAD_OVERLAY_INDEX[nameOrId]
        if index then return nameOrId, index end
        nameOrId = tonumber(nameOrId)
    end

    if type(nameOrId) == "number" then
        local name = const.HEAD_OVERLAYS[nameOrId + 1]
        if name then return name, nameOrId end
    end

    return nil, nil
end

--- Resolves "noseWidth" / 0 to both the feature name and its index.
function Skin.resolveFeature(nameOrIndex)
    local const = Skin.const

    if type(nameOrIndex) == "string" then
        local index = const.FACE_FEATURE_INDEX[nameOrIndex]
        if index then return nameOrIndex, index end
        nameOrIndex = tonumber(nameOrIndex)
    end

    if type(nameOrIndex) == "number" then
        local name = const.FACE_FEATURES[nameOrIndex + 1]
        if name then return name, nameOrIndex end
    end

    return nil, nil
end

--- The appearance currently held for the local ped, creating a default when the
--- ped has never been touched by this resource.
function Skin.getCurrent()
    if not Skin.client.current then
        Skin.client.current = Skin.read(PlayerPedId())
    end
    return Skin.client.current
end
