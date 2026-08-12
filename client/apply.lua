Skin = Skin or {}

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
function Skin.applyTo(ped, appearance, opts)
    opts = opts or {}

    -- 1. Model -------------------------------------------------------------
    if not opts.skipModel and appearance.model then
        local ok, reason = Skin.ped.setModel(appearance.model)
        if not ok then return false, reason end

        -- The model change replaces the ped handle.
        ped = PlayerPedId()
    end

    if not ped or ped == 0 or not DoesEntityExist(ped) then
        return false, "ped does not exist"
    end

    -- Legacy global indices can only be resolved against a real ped.
    Skin.components.resolveLegacy(ped, appearance)

    local freemode = Skin.schema.isFreemode(GetEntityModel(ped))

    if freemode then
        -- 2. Head blend ----------------------------------------------------
        Skin.head.applyBlend(ped, appearance.headBlend)

        -- 3. Face features -------------------------------------------------
        Skin.head.applyFeatures(ped, appearance.faceFeatures)

        -- 4. Head overlays -------------------------------------------------
        Skin.head.applyOverlays(ped, appearance.headOverlays)

        -- 5. Eye colour ----------------------------------------------------
        Skin.head.applyEyeColor(ped, appearance.eyeColor)

        -- 6. Hair ----------------------------------------------------------
        local validated = Skin.hair.validate(ped, appearance.hair)
        if validated then appearance.hair = validated end
        Skin.hair.apply(ped, appearance.hair)
    end

    -- 7. Components / props ---------------------------------------------
    Skin.components.applyAll(ped, appearance, opts.explicit)

    -- 8. Decorations (tattoos + hair fade) -------------------------------
    Skin.tattoos.apply(ped, appearance)

    return true
end

--- Applies a full appearance to the local ped and caches it.
--- @return boolean ok, string|nil reason
function Skin.apply(input, opts)
    opts = opts or {}

    if Skin.client.busy then
        return false, "another apply is already running"
    end

    Skin.client.busy = true

    local appearance = Skin.schema.normalize(input)
    local ok, reason = Skin.applyTo(PlayerPedId(), appearance, opts)

    Skin.client.busy = false

    if not ok then
        Skin.err("apply failed:", reason)
        return false, reason
    end

    Skin.client.current = appearance
    Skin.onApplied(appearance)

    return true
end

--- Merges a partial appearance onto the current one.
---
--- Only the touched subsystems are re-applied - except for model, hair and
--- tattoos, which force the pipeline from their step downwards because the
--- natives below them destroy state.
function Skin.update(partial)
    if type(partial) ~= "table" then return false, "partial must be a table" end

    local current = Skin.getCurrent()
    local merged, touched = Skin.schema.merge(current, partial)

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

    if Skin.client.busy then return false, "another apply is already running" end
    Skin.client.busy = true

    local ok, reason = Skin.applyTo(ped, merged, { skipModel = skipModel, explicit = explicit })

    Skin.client.busy = false

    if not ok then
        Skin.err("update failed:", reason)
        return false, reason
    end

    Skin.client.current = merged
    Skin.onApplied(merged)

    return true
end

--- Fired after every successful pipeline run. Sync hooks in here.
function Skin.onApplied(appearance)
    TriggerEvent("nvx_skin:applied", Skin.path.copy(appearance))

    if Skin.sync then
        Skin.sync.push(appearance)
    end
end
