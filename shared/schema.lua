Skin = Skin or {}

local const = Skin.const
local path = Skin.path

local schema = {}
Skin.schema = schema

local function clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

local function num(value, fallback)
    local n = tonumber(value)
    if n == nil then return fallback end
    return n
end

local function int(value, fallback)
    local n = tonumber(value)
    if n == nil then return fallback end
    return math.floor(n)
end

-----------------------------------------------------------------------------
-- Defaults
-----------------------------------------------------------------------------

--- Builds a fresh default appearance for the given sex.
--- @param sex string|nil "male" (default) or "female"
function schema.default(sex)
    sex = sex == "female" and "female" or "male"

    local out = {
        version = const.VERSION,
        model = sex == "female" and const.MODEL_FEMALE or const.MODEL_MALE,
        headBlend = {
            shapeFirst = 0,
            shapeSecond = 21,
            skinFirst = 0,
            skinSecond = 21,
            shapeMix = 0.5,
            skinMix = 0.5
        },
        faceFeatures = {},
        headOverlays = {},
        eyeColor = 0,
        hair = {
            collection = const.BASE_COLLECTION,
            drawable = 0,
            texture = 0,
            color = 0,
            highlight = 0,
            fade = nil
        },
        components = {},
        props = {},
        tattoos = {}
    }

    for i = 1, #const.FACE_FEATURES do
        out.faceFeatures[const.FACE_FEATURES[i]] = 0.0
    end

    for i = 1, #const.HEAD_OVERLAYS do
        local name = const.HEAD_OVERLAYS[i]
        out.headOverlays[name] = {
            style = const.OVERLAY_NONE,
            opacity = 0.0,
            colorType = const.OVERLAY_COLOR_TYPE[name] or 0,
            color = 0,
            secondColor = 0
        }
    end

    local naked = const.NAKED[sex]
    for name in pairs(const.COMPONENTS) do
        local base = naked and naked[name]
        out.components[name] = {
            collection = const.BASE_COLLECTION,
            drawable = base and base.drawable or 0,
            texture = base and base.texture or 0,
            palette = 0
        }
    end

    for name in pairs(const.PROPS) do
        out.props[name] = {
            collection = const.BASE_COLLECTION,
            drawable = -1,
            texture = 0
        }
    end

    return out
end

-----------------------------------------------------------------------------
-- Legacy input
-----------------------------------------------------------------------------

-- nvx_charcreator scales values the way skinchanger did. Detect and undo it.
local function unscaleFaceFeature(value)
    local n = num(value, 0.0)
    -- Charcreator stores -10 .. 10, the native wants -1.0 .. 1.0.
    if n < -1.0 or n > 1.0 then n = n / 10.0 end
    return clamp(n, -1.0, 1.0)
end

local function unscaleMix(value)
    local n = num(value, 0.5)
    -- Charcreator stores 0 .. 100 for the mix sliders.
    if n > 1.0 then n = n / 100.0 end
    return clamp(n, 0.0, 1.0)
end

local function unscaleOpacity(value)
    local n = num(value, 0.0)
    -- Charcreator stores 0 .. 10.
    if n > 1.0 then n = n / 10.0 end
    return clamp(n, 0.0, 1.0)
end

--- Flattens the charcreator's zone-keyed tattoo table into a flat list and
--- strips UI metadata (label, zone, name) that has no business in a skin.
local function normalizeTattoos(input)
    local out = {}
    if type(input) ~= "table" then return out end

    local function add(entry)
        if type(entry) ~= "table" then return end

        local collection = entry.collection
        if not collection then return end

        local male = entry.male or entry.hashMale
        local female = entry.female or entry.hashFemale

        -- A single-hash entry (already resolved) is kept for both sexes so it at
        -- least survives; it just will not swap on a gender change.
        male = male or entry.overlay or entry.hash
        female = female or entry.overlay or entry.hash
        if not male and not female then return end

        out[#out + 1] = {
            collection = collection,
            male = male or female,
            female = female or male
        }
    end

    for _, value in pairs(input) do
        if type(value) == "table" then
            if value.collection then
                add(value)
            else
                -- zone bucket
                for _, entry in pairs(value) do
                    add(entry)
                end
            end
        end
    end

    return out
end

-----------------------------------------------------------------------------
-- Normalization
-----------------------------------------------------------------------------

local function normalizeSlot(input, default, isProp)
    local out = {
        collection = default.collection,
        drawable = default.drawable,
        texture = default.texture
    }

    if not isProp then out.palette = default.palette end
    if type(input) ~= "table" then return out end

    out.drawable = int(input.drawable, out.drawable)
    out.texture = int(input.texture, out.texture)
    if not isProp then out.palette = int(input.palette, out.palette) end

    if type(input.collection) == "string" then
        out.collection = input.collection
    else
        -- No collection given: the drawable is a legacy global index. It can only
        -- be resolved against a real ped, so just flag it for the client.
        out.legacy = true
    end

    if isProp and out.drawable < -1 then out.drawable = -1 end
    if not isProp and out.drawable < 0 then out.drawable = 0 end
    if out.texture < 0 then out.texture = 0 end

    return out
end

--- Brings any appearance-shaped table into the canonical schema.
--- Accepts the current nvx_charcreator shape and legacy global indices.
--- @param input table|nil
--- @return table appearance
function schema.normalize(input)
    input = type(input) == "table" and input or {}

    -- `sex` is the charcreator's model stand-in.
    local sex = input.sex
    if sex ~= "male" and sex ~= "female" then sex = nil end

    local model = input.model
    if not model and sex then
        model = sex == "female" and const.MODEL_FEMALE or const.MODEL_MALE
    end

    if not sex and model then
        sex = schema.sexOf(model)
    end

    local out = schema.default(sex)
    if model then out.model = model end

    -- Head blend --------------------------------------------------------------
    local blend = input.headBlend
    if type(blend) == "table" then
        local b = out.headBlend
        b.shapeFirst = int(blend.shapeFirst or blend.father, b.shapeFirst)
        b.shapeSecond = int(blend.shapeSecond or blend.mother, b.shapeSecond)
        b.skinFirst = int(blend.skinFirst or blend.father, b.shapeFirst)
        b.skinSecond = int(blend.skinSecond or blend.mother, b.shapeSecond)
        b.shapeMix = unscaleMix(blend.shapeMix ~= nil and blend.shapeMix or b.shapeMix)
        b.skinMix = unscaleMix(blend.skinMix ~= nil and blend.skinMix or b.skinMix)
    end

    schema.applyHeadBlendLink(out.headBlend)

    -- Face features -----------------------------------------------------------
    local features = input.faceFeatures
    if type(features) == "table" then
        for i = 1, #const.FACE_FEATURES do
            local name = const.FACE_FEATURES[i]
            local value = features[name]
            if value == nil then value = features[i - 1] end
            if value ~= nil then
                out.faceFeatures[name] = unscaleFaceFeature(value)
            end
        end
    end

    -- Head overlays -----------------------------------------------------------
    local overlays = input.headOverlays
    if type(overlays) == "table" then
        for i = 1, #const.HEAD_OVERLAYS do
            local name = const.HEAD_OVERLAYS[i]
            local src = overlays[name]
            if src == nil then src = overlays[i - 1] end

            if type(src) == "table" then
                local dst = out.headOverlays[name]
                dst.style = int(src.style, dst.style)
                dst.opacity = unscaleOpacity(src.opacity)
                dst.color = int(src.color, dst.color)
                dst.secondColor = int(src.secondColor, dst.secondColor)
                dst.colorType = int(src.colorType, dst.colorType)

                -- Style 0 with zero opacity is the charcreator's "off"; the
                -- native wants 255.
                if dst.style < 0 then dst.style = const.OVERLAY_NONE end
            end
        end
    end

    out.eyeColor = int(input.eyeColor, out.eyeColor)

    -- Hair --------------------------------------------------------------------
    local hair = input.hair
    if type(hair) == "table" then
        local h = out.hair
        h.drawable = int(hair.drawable ~= nil and hair.drawable or hair.style, h.drawable)
        h.texture = int(hair.texture, h.texture)
        h.color = int(hair.color, h.color)
        h.highlight = int(hair.highlight, h.highlight)

        if type(hair.collection) == "string" then
            h.collection = hair.collection
        elseif hair.style ~= nil or hair.drawable ~= nil then
            h.legacy = true
        end

        -- fade: false = off, table = explicit override, true/"auto" = drop the
        -- override and fall back to the per-style lookup.
        --
        -- The sentinel exists because a partial update cannot carry nil: a key
        -- set to nil simply is not in the table, so there would otherwise be no
        -- way to clear an override once it is set.
        if hair.fade == false then
            h.fade = false
        elseif hair.fade == true or hair.fade == "auto" then
            h.fade = nil
        elseif type(hair.fade) == "table" and hair.fade.collection and hair.fade.overlay then
            h.fade = { collection = hair.fade.collection, overlay = hair.fade.overlay }
        end
    end

    -- Components / props ------------------------------------------------------
    local components = input.components
    if type(components) == "table" then
        for name in pairs(const.COMPONENTS) do
            local src = components[name]
            if src == nil then src = components[const.COMPONENTS[name]] end
            if src ~= nil then
                out.components[name] = normalizeSlot(src, out.components[name], false)
            end
        end
    end

    local props = input.props
    if type(props) == "table" then
        for name in pairs(const.PROPS) do
            local src = props[name]
            if src == nil then src = props[const.PROPS[name]] end
            if src ~= nil then
                out.props[name] = normalizeSlot(src, out.props[name], true)
            end
        end
    end

    out.tattoos = normalizeTattoos(input.tattoos)
    out.version = const.VERSION

    return out
end

--- Applies Config.HeadBlend coupling to a head blend table, in place.
--- Both skin and shape fields always stay present - the coupling only
--- overwrites values, it never removes them from the schema.
function schema.applyHeadBlendLink(blend)
    if type(blend) ~= "table" then return blend end

    local cfg = Config and Config.HeadBlend
    if not cfg then return blend end

    if cfg.linkSkinToParents then
        blend.skinFirst = blend.shapeFirst
        blend.skinSecond = blend.shapeSecond
    end

    if cfg.linkSkinMix then
        blend.skinMix = blend.shapeMix
    end

    return blend
end

--- Merges a partial appearance onto a full one and re-normalizes.
--- @return table appearance, table touched top-level keys that changed
function schema.merge(base, partial)
    local merged = path.copy(base)
    path.merge(merged, partial)

    -- `tattoos` is the only list in the schema, and a list is a value, not
    -- something to merge into. Without this an empty list would merge to a
    -- no-op and ClearTattoos()/SetTattoos({}) would silently do nothing.
    if type(partial) == "table" and partial.tattoos ~= nil then
        merged.tattoos = path.copy(partial.tattoos)
    end

    local touched = {}
    if type(partial) == "table" then
        for key in pairs(partial) do touched[key] = true end
    end

    return schema.normalize(merged), touched
end

--- Normalizes a model reference to an unsigned hash.
---
--- Necessary because GetEntityModel can hand back a signed 32-bit value while
--- joaat/backtick literals are unsigned - comparing them directly silently
--- fails for every hash with the high bit set.
function schema.hashOf(model)
    if model == nil then return nil end
    if type(model) == "string" then return joaat(model) end

    local hash = math.floor(model)
    if hash < 0 then hash = hash + 0x100000000 end

    return hash
end

--- Resolves the sex a model implies. Returns nil for non-freemode peds.
function schema.sexOf(model)
    local hash = schema.hashOf(model)
    if not hash then return nil end
    return const.FREEMODE[hash]
end

function schema.isFreemode(model)
    return schema.sexOf(model) ~= nil
end
