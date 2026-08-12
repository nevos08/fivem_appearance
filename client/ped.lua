Appearance = Appearance or {}

local ped = {}
Appearance.ped = ped

--- Loads a model and switches the local player to it.
---
--- Changing the model resets components, overlays AND decorations, so every
--- caller must re-apply the full appearance afterwards. It also resets health
--- and armour, which is restored here when configured.
---
--- @return boolean ok, string|nil reason
function ped.setModel(model)
    local hash = type(model) == "string" and joaat(model) or model

    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        return false, ("invalid model '%s'"):format(tostring(model))
    end

    local playerPed = PlayerPedId()

    if GetEntityModel(playerPed) == hash then
        return true
    end

    local health = GetEntityHealth(playerPed)
    local maxHealth = GetEntityMaxHealth(playerPed)
    local armour = GetPedArmour(playerPed)

    RequestModel(hash)

    local deadline = GetGameTimer() + Config.ModelLoadTimeout
    while not HasModelLoaded(hash) do
        if GetGameTimer() > deadline then
            SetModelAsNoLongerNeeded(hash)
            return false, ("model '%s' failed to load in time"):format(tostring(model))
        end
        Wait(0)
    end

    SetPlayerModel(PlayerId(), hash)
    SetModelAsNoLongerNeeded(hash)

    playerPed = PlayerPedId()
    SetPedDefaultComponentVariation(playerPed)

    if Config.RestoreHealth then
        SetEntityMaxHealth(playerPed, maxHealth)
        SetEntityHealth(playerPed, health)
    end

    if Config.RestoreArmour then
        SetPedArmour(playerPed, armour)
    end

    return true
end
