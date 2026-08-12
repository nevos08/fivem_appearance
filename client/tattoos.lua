Skin = Skin or {}

local tattoos = {}
Skin.tattoos = tattoos

local function toHash(value)
    if type(value) == "string" then return joaat(value) end
    return value
end

--- Applies tattoos AND the hair fade.
---
--- ClearPedDecorations wipes the whole decoration slot, so both have to be
--- written in the same step even though they are separate subsystems - that is
--- the reason the fade is not applied together with the hair component.
function tattoos.apply(ped, appearance)
    ClearPedDecorations(ped)

    local list = appearance.tattoos or {}
    local sex = Skin.schema.sexOf(appearance.model) or "male"

    for i = 1, #list do
        local tattoo = list[i]
        local overlay = sex == "female" and tattoo.female or tattoo.male

        if tattoo.collection and overlay then
            AddPedDecorationFromHashes(ped, toHash(tattoo.collection), toHash(overlay))
        end
    end

    local fade = Skin.hair.resolveFade(appearance.model, appearance.hair)
    if fade then
        AddPedDecorationFromHashes(ped, toHash(fade.collection), toHash(fade.overlay))
    end
end

--- Tattoos are compared by collection + both hashes, so the same tattoo cannot
--- be added twice through different catalog entries.
function tattoos.indexOf(list, tattoo)
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
