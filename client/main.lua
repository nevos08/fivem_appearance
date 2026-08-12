Skin = Skin or {}

local const = Skin.const
local copy = Skin.path.copy

-----------------------------------------------------------------------------
-- Whole appearance
-----------------------------------------------------------------------------

local function Apply(appearance, opts) return Skin.apply(appearance, opts) end
local function Update(partial) return Skin.update(partial) end
local function GetAppearance() return copy(Skin.getCurrent()) end

local function Read(ped)
    local appearance, partial = Skin.read(ped or PlayerPedId())
    return appearance, partial
end

local function Get(pathStr)
    local current = Skin.getCurrent()
    if not pathStr then return copy(current) end
    return copy(Skin.path.get(current, pathStr))
end

local function Reset()
    local sex = Skin.schema.sexOf(GetEntityModel(PlayerPedId())) or "male"
    return Skin.apply(Skin.schema.default(sex))
end

local function SetNaked()
    local current = Skin.getCurrent()
    local sex = Skin.schema.sexOf(current.model) or "male"
    local naked = const.NAKED[sex] or {}

    local components = {}
    for name, entry in pairs(naked) do
        components[name] = { collection = const.BASE_COLLECTION, drawable = entry.drawable, texture = entry.texture, palette = 0 }
    end

    local props = {}
    for name in pairs(const.PROPS) do
        props[name] = { collection = const.BASE_COLLECTION, drawable = -1, texture = 0 }
    end

    return Skin.update({ components = components, props = props })
end

-----------------------------------------------------------------------------
-- Model
-----------------------------------------------------------------------------

local function SetModel(model) return Skin.update({ model = model }) end
local function GetModel() return Skin.getCurrent().model end
local function GetSex() return Skin.schema.sexOf(Skin.getCurrent().model) end
local function IsFreemode() return Skin.schema.isFreemode(Skin.getCurrent().model) end

-----------------------------------------------------------------------------
-- Head
-----------------------------------------------------------------------------

local function SetHeadBlend(blend) return Skin.update({ headBlend = blend }) end
local function GetHeadBlend() return copy(Skin.getCurrent().headBlend) end

local function SetFaceFeature(nameOrIndex, value)
    local name = Skin.resolveFeature(nameOrIndex)
    if not name then return false, "unknown face feature" end
    return Skin.update({ faceFeatures = { [name] = value } })
end

local function GetFaceFeature(nameOrIndex)
    local name = Skin.resolveFeature(nameOrIndex)
    if not name then return nil end
    return Skin.getCurrent().faceFeatures[name]
end

local function SetFaceFeatures(tbl) return Skin.update({ faceFeatures = tbl }) end
local function GetFaceFeatures() return copy(Skin.getCurrent().faceFeatures) end

local function SetOverlay(nameOrId, style, opacity, color, secondColor)
    local name = Skin.resolveOverlay(nameOrId)
    if not name then return false, "unknown overlay" end

    return Skin.update({
        headOverlays = {
            [name] = {
                style = style,
                opacity = opacity,
                color = color,
                secondColor = secondColor
            }
        }
    })
end

local function GetOverlay(nameOrId)
    local name = Skin.resolveOverlay(nameOrId)
    if not name then return nil end
    return copy(Skin.getCurrent().headOverlays[name])
end

local function SetOverlays(tbl) return Skin.update({ headOverlays = tbl }) end
local function GetOverlays() return copy(Skin.getCurrent().headOverlays) end

local function SetEyeColor(color) return Skin.update({ eyeColor = color }) end
local function GetEyeColor() return Skin.getCurrent().eyeColor end

-----------------------------------------------------------------------------
-- Hair (fade always travels with the style)
-----------------------------------------------------------------------------

local function SetHair(collection, drawable, texture, color, highlight, fade)
    return Skin.update({
        hair = {
            collection = collection,
            drawable = drawable,
            texture = texture,
            color = color,
            highlight = highlight,
            fade = fade
        }
    })
end

local function GetHair() return copy(Skin.getCurrent().hair) end

local function SetHairStyle(collection, drawable, texture)
    return Skin.update({ hair = { collection = collection, drawable = drawable, texture = texture } })
end

local function GetHairStyle()
    local hair = Skin.getCurrent().hair
    return hair.collection, hair.drawable, hair.texture
end

local function SetHairColor(color, highlight)
    return Skin.update({ hair = { color = color, highlight = highlight } })
end

local function GetHairColor()
    local hair = Skin.getCurrent().hair
    return hair.color, hair.highlight
end

local function SetHairFade(fade) return Skin.update({ hair = { fade = fade } }) end

local function GetHairFade()
    local current = Skin.getCurrent()
    local fade = Skin.hair.resolveFade(current.model, current.hair)
    return fade and copy(fade) or fade
end

-----------------------------------------------------------------------------
-- Clothing
-----------------------------------------------------------------------------

local function SetComponent(nameOrId, collection, drawable, texture, palette)
    local name = Skin.resolveComponent(nameOrId)
    if not name then return false, "unknown component" end

    return Skin.update({
        components = {
            [name] = {
                collection = collection,
                drawable = drawable,
                texture = texture,
                palette = palette
            }
        }
    })
end

local function GetComponent(nameOrId)
    local name = Skin.resolveComponent(nameOrId)
    if not name then return nil end
    return copy(Skin.getCurrent().components[name])
end

local function SetComponents(tbl) return Skin.update({ components = tbl }) end
local function GetComponents() return copy(Skin.getCurrent().components) end

local function ClearComponent(nameOrId)
    local name = Skin.resolveComponent(nameOrId)
    if not name then return false, "unknown component" end

    local sex = Skin.schema.sexOf(Skin.getCurrent().model) or "male"
    local naked = const.NAKED[sex] and const.NAKED[sex][name]

    return Skin.update({
        components = {
            [name] = {
                collection = const.BASE_COLLECTION,
                drawable = naked and naked.drawable or 0,
                texture = naked and naked.texture or 0,
                palette = 0
            }
        }
    })
end

local function SetProp(nameOrId, collection, drawable, texture)
    local name = Skin.resolveProp(nameOrId)
    if not name then return false, "unknown prop" end

    return Skin.update({
        props = { [name] = { collection = collection, drawable = drawable, texture = texture } }
    })
end

local function GetProp(nameOrId)
    local name = Skin.resolveProp(nameOrId)
    if not name then return nil end
    return copy(Skin.getCurrent().props[name])
end

local function SetProps(tbl) return Skin.update({ props = tbl }) end
local function GetProps() return copy(Skin.getCurrent().props) end

local function ClearProp(nameOrId)
    local name = Skin.resolveProp(nameOrId)
    if not name then return false, "unknown prop" end

    return Skin.update({
        props = { [name] = { collection = const.BASE_COLLECTION, drawable = -1, texture = 0 } }
    })
end

-----------------------------------------------------------------------------
-- Tattoos
-----------------------------------------------------------------------------

local function SetTattoos(list) return Skin.update({ tattoos = list or {} }) end
local function GetTattoos() return copy(Skin.getCurrent().tattoos) end

local function HasTattoo(tattoo)
    return Skin.tattoos.indexOf(Skin.getCurrent().tattoos, tattoo) ~= nil
end

local function AddTattoo(tattoo)
    local list = copy(Skin.getCurrent().tattoos)
    if Skin.tattoos.indexOf(list, tattoo) then return true end

    list[#list + 1] = tattoo
    return Skin.update({ tattoos = list })
end

local function RemoveTattoo(tattoo)
    local list = copy(Skin.getCurrent().tattoos)
    local index = Skin.tattoos.indexOf(list, tattoo)
    if not index then return false, "tattoo not present" end

    table.remove(list, index)
    return Skin.update({ tattoos = list })
end

local function ClearTattoos() return Skin.update({ tattoos = {} }) end

-----------------------------------------------------------------------------
-- Collections / validation
-----------------------------------------------------------------------------

local function IsValid(nameOrId, collection, drawable, texture)
    local name = Skin.resolveComponent(nameOrId)
    if not name then return false, "unknown component" end

    local slot = { collection = collection, drawable = drawable, texture = texture or 0, palette = 0 }
    local validated, reason = Skin.collections.validateComponent(PlayerPedId(), name, slot)

    if not validated then return false, reason end

    -- Under "clamp" a corrected value still counts as invalid input.
    local exact = validated.drawable == drawable and validated.texture == (texture or 0)
    return exact, exact and nil or "value was corrected"
end

-- Numeric ids are ambiguous between components and props (1 is both `mask` and
-- `glasses`), so components win and callers should prefer names.
--- @param drawable number|nil texture count is per-drawable, so without this the
---        second return value is always 0
--- @return number drawables, number textures
local function GetVariationCounts(nameOrId, collection, drawable)
    local ped = PlayerPedId()

    local name, componentId = Skin.resolveVariationTarget(nameOrId)
    if name then
        return Skin.collections.componentCounts(ped, componentId, collection, drawable)
    end

    local propName, anchor = Skin.resolveProp(nameOrId)
    if propName then
        return Skin.collections.propCounts(ped, anchor, collection, drawable)
    end

    return 0, 0
end

local function GetCollections() return Skin.collections.list(PlayerPedId()) end

local function ToGlobalIndex(nameOrId, collection, drawable)
    local ped = PlayerPedId()

    local name, componentId = Skin.resolveVariationTarget(nameOrId)
    if name then return Skin.collections.toGlobalDrawable(ped, componentId, collection, drawable) end

    local propName, anchor = Skin.resolveProp(nameOrId)
    if propName then return Skin.collections.toGlobalProp(ped, anchor, collection, drawable) end

    return nil
end

local function FromGlobalIndex(nameOrId, globalDrawable)
    local ped = PlayerPedId()

    local name, componentId = Skin.resolveVariationTarget(nameOrId)
    if name then return Skin.collections.fromGlobalDrawable(ped, componentId, globalDrawable) end

    local propName, anchor = Skin.resolveProp(nameOrId)
    if propName then return Skin.collections.fromGlobalProp(ped, anchor, globalDrawable) end

    return nil
end

-----------------------------------------------------------------------------
-- Clipping / forced components
-----------------------------------------------------------------------------

local function slotFor(collection, drawable, texture)
    return { collection = collection or const.BASE_COLLECTION, drawable = drawable, texture = texture or 0 }
end

local function GetItemHash(nameOrId, collection, drawable, texture)
    local ped = PlayerPedId()

    local name = Skin.resolveComponent(nameOrId)
    if name then return Skin.clothing.itemHash(ped, name, slotFor(collection, drawable, texture)) end

    local propName = Skin.resolveProp(nameOrId)
    if propName then return Skin.clothing.propItemHash(ped, propName, slotFor(collection, drawable, texture)) end

    return 0
end

local function GetForcedComponents(nameOrId, collection, drawable, texture)
    local name = Skin.resolveComponent(nameOrId)
    if not name then return {} end
    return Skin.clothing.forcedComponents(PlayerPedId(), name, slotFor(collection, drawable, texture))
end

local function GetForcedProps(nameOrId, collection, drawable, texture)
    local name = Skin.resolveComponent(nameOrId)
    if not name then return {} end
    return Skin.clothing.forcedProps(PlayerPedId(), name, slotFor(collection, drawable, texture))
end

local function GetVariants(nameOrId, collection, drawable, texture)
    local name = Skin.resolveComponent(nameOrId)
    if not name then return {} end
    return Skin.clothing.variants(PlayerPedId(), name, slotFor(collection, drawable, texture))
end

--- Resolves a component set without applying it, so a creator can preview what
--- a piece of clothing does to the rest of the outfit before committing.
---
--- Nothing is treated as explicit here on purpose: the point of a preview is to
--- show what the forced components actually do to the outfit.
--- @return table components, table props
local function ResolveOutfit(components)
    return Skin.clothing.resolve(PlayerPedId(), components or {}, {})
end

-----------------------------------------------------------------------------
-- Exports
-----------------------------------------------------------------------------

local api = {
    Apply = Apply, Update = Update, GetAppearance = GetAppearance, Read = Read,
    Get = Get, Reset = Reset, SetNaked = SetNaked,

    SetModel = SetModel, GetModel = GetModel, GetSex = GetSex, IsFreemode = IsFreemode,

    SetHeadBlend = SetHeadBlend, GetHeadBlend = GetHeadBlend,
    SetFaceFeature = SetFaceFeature, GetFaceFeature = GetFaceFeature,
    SetFaceFeatures = SetFaceFeatures, GetFaceFeatures = GetFaceFeatures,
    SetOverlay = SetOverlay, GetOverlay = GetOverlay,
    SetOverlays = SetOverlays, GetOverlays = GetOverlays,
    SetEyeColor = SetEyeColor, GetEyeColor = GetEyeColor,

    SetHair = SetHair, GetHair = GetHair,
    SetHairStyle = SetHairStyle, GetHairStyle = GetHairStyle,
    SetHairColor = SetHairColor, GetHairColor = GetHairColor,
    SetHairFade = SetHairFade, GetHairFade = GetHairFade,

    SetComponent = SetComponent, GetComponent = GetComponent,
    SetComponents = SetComponents, GetComponents = GetComponents,
    ClearComponent = ClearComponent,
    SetProp = SetProp, GetProp = GetProp,
    SetProps = SetProps, GetProps = GetProps,
    ClearProp = ClearProp,

    SetTattoos = SetTattoos, GetTattoos = GetTattoos,
    AddTattoo = AddTattoo, RemoveTattoo = RemoveTattoo,
    HasTattoo = HasTattoo, ClearTattoos = ClearTattoos,

    IsValid = IsValid, GetVariationCounts = GetVariationCounts, GetCollections = GetCollections,
    ToGlobalIndex = ToGlobalIndex, FromGlobalIndex = FromGlobalIndex,

    GetItemHash = GetItemHash, GetForcedComponents = GetForcedComponents,
    GetForcedProps = GetForcedProps, GetVariants = GetVariants, ResolveOutfit = ResolveOutfit
}

for name, fn in pairs(api) do
    exports(name, fn)
end

-----------------------------------------------------------------------------
-- Server -> client routing
-----------------------------------------------------------------------------

RegisterNetEvent("nvx_skin:call", function(action, args)
    local fn = api[action]
    if not fn then
        Skin.warn(("server called unknown action '%s'"):format(tostring(action)))
        return
    end

    fn(table.unpack(args or {}, 1, args and args.n or 0))
end)

RegisterNetEvent("nvx_skin:request", function(id, action, args)
    local fn = api[action]

    if not fn then
        TriggerServerEvent("nvx_skin:response", id, nil)
        return
    end

    local results = table.pack(fn(table.unpack(args or {}, 1, args and args.n or 0)))
    TriggerServerEvent("nvx_skin:response", id, results)
end)

-----------------------------------------------------------------------------
-- Debug commands
-----------------------------------------------------------------------------

CreateThread(function()
    if not Config.Debug or not Config.DebugCommands then return end

    RegisterCommand("nvxskin_dump", function()
        print(json.encode(GetAppearance(), { indent = true }))
    end, false)

    RegisterCommand("nvxskin_collections", function(_, args)
        local nameOrId = args[1]
        if not nameOrId then
            print(json.encode(GetCollections()))
            return
        end

        local out = {}
        for _, collection in ipairs(GetCollections()) do
            local drawables = GetVariationCounts(nameOrId, collection)
            if drawables > 0 then out[collection] = drawables end
        end
        print(json.encode(out, { indent = true }))
    end, false)

    RegisterCommand("nvxskin_random", function()
        local ped = PlayerPedId()
        local components = {}

        for name, componentId in pairs(const.COMPONENTS) do
            local drawables = Skin.collections.componentCounts(ped, componentId, const.BASE_COLLECTION)
            if drawables > 0 then
                local drawable = math.random(0, drawables - 1)
                local _, textures = Skin.collections.componentCounts(ped, componentId, const.BASE_COLLECTION, drawable)
                components[name] = {
                    collection = const.BASE_COLLECTION,
                    drawable = drawable,
                    texture = textures > 0 and math.random(0, textures - 1) or 0,
                    palette = 0
                }
            end
        end

        Update({ components = components })
    end, false)

    RegisterCommand("nvxskin_set", function(_, args)
        local pathStr, value = args[1], args[2]
        if not pathStr or value == nil then
            print("usage: /nvxskin_set <path> <value>")
            return
        end

        local partial = {}
        Skin.path.set(partial, pathStr, tonumber(value) or value)

        local ok, reason = Update(partial)
        print(ok and "ok" or ("failed: " .. tostring(reason)))
    end, false)
end)
