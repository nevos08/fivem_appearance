Appearance = Appearance or {}

--- The apply pipeline.
---
--- The order is not optional. Each step destroys state written by the ones
--- above it:
---   1 model      resets components, overlays AND decorations
---   2 headBlend  must precede the overlays or they do not take
---   8 decorations ClearPedDecorations wipes tattoos and the hair fade together
---
--- Getting this wrong is exactly why skinchanger-based setups lose tattoos on a
--- model change.
---
--- @param appearance table already normalized
--- @param opts table|nil { skipModel, remote, explicit }
--- @return boolean ok, string|nil reason
function Appearance.applyTo(ped, appearance, opts)
    opts = opts or {}

    -- 1. Model -------------------------------------------------------------
    if not opts.skipModel and appearance.model then
        local ok, reason = Appearance.ped.setModel(appearance.model)
        if not ok then return false, reason end

        -- The model change replaces the ped handle.
        ped = PlayerPedId()
    end

    if not ped or ped == 0 or not DoesEntityExist(ped) then
        return false, "ped does not exist"
    end

    -- Legacy global indices can only be resolved against a real ped.
    Appearance.components.resolveLegacy(ped, appearance)

    local freemode = Appearance.schema.isFreemode(GetEntityModel(ped))

    if freemode then
        -- 2. Head blend ----------------------------------------------------
        Appearance.head.applyBlend(ped, appearance.headBlend)

        -- 3. Face features -------------------------------------------------
        Appearance.head.applyFeatures(ped, appearance.faceFeatures)

        -- 4. Head overlays -------------------------------------------------
        Appearance.head.applyOverlays(ped, appearance.headOverlays)

        -- 5. Eye colour ----------------------------------------------------
        Appearance.head.applyEyeColor(ped, appearance.eyeColor)

        -- 6. Hair ----------------------------------------------------------
        local validated, hairReason = Appearance.hair.validate(ped, appearance.hair)
        if not validated then
            if Config.Validation == "reject" then return false, hairReason end
        else
            appearance.hair = validated
        end
        Appearance.hair.apply(ped, appearance.hair)
    end

    -- 7. Components / props ---------------------------------------------
    local ok, reason = Appearance.components.applyAll(ped, appearance, opts.explicit)
    if not ok then return false, reason end

    -- 8. Decorations (tattoos + hair fade) -------------------------------
    Appearance.tattoos.apply(ped, appearance)

    return true
end

--- Applies a full appearance to the local ped and caches it.
--- @return boolean ok, string|nil reason
function Appearance.apply(input, opts)
    opts = opts or {}

    if Appearance.client.busy then
        return false, "another apply is already running"
    end

    Appearance.client.busy = true

    local appearance = Appearance.schema.normalize(input)
    local ok, reason = Appearance.applyTo(PlayerPedId(), appearance, opts)

    Appearance.client.busy = false

    if not ok then
        Appearance.err("apply failed:", reason)
        return false, reason
    end

    Appearance.client.current = appearance
    Appearance.onApplied(appearance)

    return true
end

--- Merges a partial appearance onto the current one.
---
--- Only the touched subsystems are re-applied - except for model, hair and
--- tattoos, which force the pipeline from their step downwards because the
--- natives below them destroy state.
function Appearance.update(partial)
    if type(partial) ~= "table" then return false, "partial must be a table" end

    local current = Appearance.getCurrent()
    local merged, touched = Appearance.schema.merge(current, partial)

    -- Slots named in the partial were set on purpose and must win over GTA's
    -- forced components.
    local explicit = {}
    if type(partial.components) == "table" then
        for name in pairs(partial.components) do explicit[name] = true end
    end
    if type(partial.props) == "table" then
        for name in pairs(partial.props) do explicit[name] = true end
    end

    local ped = PlayerPedId()
    local skipModel = not touched.model

    if Appearance.client.busy then return false, "another apply is already running" end
    Appearance.client.busy = true

    local ok, reason = Appearance.applyTo(ped, merged, { skipModel = skipModel, explicit = explicit })

    Appearance.client.busy = false

    if not ok then
        Appearance.err("update failed:", reason)
        return false, reason
    end

    Appearance.client.current = merged
    Appearance.onApplied(merged)

    return true
end

--- Fired after every successful pipeline run. Sync hooks in here.
function Appearance.onApplied(appearance)
    TriggerEvent("nvx_appearance:applied", Appearance.path.copy(appearance))

    if Appearance.sync then
        Appearance.sync.push(appearance)
    end
end
