Skin = Skin or {}

local const = Skin.const
local copy = Skin.path.copy
local sync = Skin.serverSync

-----------------------------------------------------------------------------
-- Setters
-----------------------------------------------------------------------------
-- Fire-and-forget: they route to the target client, which owns the natives.
-- They work regardless of Config.Sync.

local SETTERS = {
    "Apply", "Update", "Reset", "SetNaked", "SetModel",
    "SetHeadBlend", "SetFaceFeature", "SetFaceFeatures",
    "SetOverlay", "SetOverlays", "SetEyeColor",
    "SetHair", "SetHairStyle", "SetHairColor", "SetHairFade",
    "SetComponent", "SetComponents", "ClearComponent",
    "SetProp", "SetProps", "ClearProp",
    "SetTattoos", "AddTattoo", "RemoveTattoo", "ClearTattoos"
}

for i = 1, #SETTERS do
    local action = SETTERS[i]

    exports(action, function(src, ...)
        if not src then return false, "missing player source" end
        Skin.call(src, action, ...)
        return true
    end)
end

-----------------------------------------------------------------------------
-- Getters
-----------------------------------------------------------------------------
-- With sync enabled these are synchronous: the statebag already holds the full
-- appearance, so a getter is just a slice. Without sync they fall back to a
-- client roundtrip and must be called from inside a coroutine.

--- @return table|nil appearance, string|nil reason
local function appearanceOf(src)
    local stored = sync.get(src)
    if stored then return stored end

    if sync.enabled() then
        -- Sync is on but nothing stored yet - the player has not applied a skin.
        return nil, "no appearance stored"
    end

    local appearance, reason = Skin.request(src, "GetAppearance")
    if not appearance then return nil, reason or "no response" end

    return appearance
end

local function slice(src, pathStr)
    local appearance, reason = appearanceOf(src)
    if not appearance then return nil, reason end

    if not pathStr then return copy(appearance) end
    return copy(Skin.path.get(appearance, pathStr))
end

local getters = {}

function getters.GetAppearance(src) return slice(src) end
function getters.Get(src, pathStr) return slice(src, pathStr) end
function getters.GetModel(src) return slice(src, "model") end
function getters.GetHeadBlend(src) return slice(src, "headBlend") end
function getters.GetFaceFeatures(src) return slice(src, "faceFeatures") end
function getters.GetOverlays(src) return slice(src, "headOverlays") end
function getters.GetEyeColor(src) return slice(src, "eyeColor") end
function getters.GetHair(src) return slice(src, "hair") end
function getters.GetComponents(src) return slice(src, "components") end
function getters.GetProps(src) return slice(src, "props") end
function getters.GetTattoos(src) return slice(src, "tattoos") end

function getters.GetSex(src)
    local model = slice(src, "model")
    return model and Skin.schema.sexOf(model) or nil
end

function getters.IsFreemode(src)
    local model = slice(src, "model")
    return model ~= nil and Skin.schema.isFreemode(model)
end

function getters.GetFaceFeature(src, nameOrIndex)
    local name = type(nameOrIndex) == "number" and const.FACE_FEATURES[nameOrIndex + 1] or nameOrIndex
    if not name then return nil, "unknown face feature" end
    return slice(src, "faceFeatures." .. name)
end

function getters.GetOverlay(src, nameOrId)
    local name = type(nameOrId) == "number" and const.HEAD_OVERLAYS[nameOrId + 1] or nameOrId
    if not name then return nil, "unknown overlay" end
    return slice(src, "headOverlays." .. name)
end

function getters.GetComponent(src, nameOrId)
    local name = type(nameOrId) == "number" and const.COMPONENT_NAMES[nameOrId] or nameOrId
    if not name then return nil, "unknown component" end
    return slice(src, "components." .. name)
end

function getters.GetProp(src, nameOrId)
    local name = type(nameOrId) == "number" and const.PROP_NAMES[nameOrId] or nameOrId
    if not name then return nil, "unknown prop" end
    return slice(src, "props." .. name)
end

function getters.GetHairColor(src)
    local hair = slice(src, "hair")
    if not hair then return nil end
    return hair.color, hair.highlight
end

function getters.GetHairStyle(src)
    local hair = slice(src, "hair")
    if not hair then return nil end
    return hair.collection, hair.drawable, hair.texture
end

function getters.GetHairFade(src)
    local hair = slice(src, "hair")
    if not hair then return nil end
    return hair.fade
end

function getters.HasTattoo(src, tattoo)
    local list = slice(src, "tattoos")
    if not list then return false end
    return Skin.tattoosIndexOf(list, tattoo) ~= nil
end

--- Always a roundtrip: read straight off the ped, ignoring the statebag.
function getters.Read(src)
    return Skin.request(src, "Read")
end

for name, fn in pairs(getters) do
    exports(name, fn)
end

-----------------------------------------------------------------------------
-- Shared helper (the client version lives in client/tattoos.lua)
-----------------------------------------------------------------------------

function Skin.tattoosIndexOf(list, tattoo)
    if type(tattoo) ~= "table" or not tattoo.collection then return nil end

    local male = tattoo.male or tattoo.hashMale
    local female = tattoo.female or tattoo.hashFemale

    for i = 1, #list do
        local entry = list[i]
        if entry.collection == tattoo.collection
            and (male == nil or entry.male == male)
            and (female == nil or entry.female == female) then
            return i
        end
    end

    return nil
end

-----------------------------------------------------------------------------
-- Startup notes
-----------------------------------------------------------------------------

CreateThread(function()
    if not Config.Sync.enabled then
        Skin.warn("sync is disabled - server-side getters will do a client roundtrip and must be called from a coroutine")
    end
end)
