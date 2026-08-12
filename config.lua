Config = {}

-- Verbose logging for every apply, validation clamp and sync event.
Config.Debug = false

-- Locale used for log/error messages. Falls back to "en" when a key is missing.
Config.Locale = "de"

-- Registers /nvxappearance_* test commands. Requires Config.Debug.
Config.DebugCommands = true

-----------------------------------------------------------------------------
-- Head blend
-----------------------------------------------------------------------------
Config.HeadBlend = {
    -- The natives allow different parents for face shape and skin tone. In
    -- practice you almost always want them identical, otherwise the skin tone
    -- does not match the face.
    linkSkinToParents = true,

    -- Additionally couple skinMix to shapeMix.
    linkSkinMix = false
}

-----------------------------------------------------------------------------
-- Clothing
-----------------------------------------------------------------------------
Config.Clothing = {
    -- GTA stores which arms / undershirt belong to a given top in
    -- SHOP_CLOTHES.meta (forcedComponentList). We read that at runtime, so
    -- there is no hand-maintained rule set to keep up to date.
    --
    -- Only works for drawables that are actual shop items. Job outfits and most
    -- addon clothing have no entry - nothing happens for those.
    applyForcedComponents = true,
    applyForcedProps = true,

    -- Prefer a non-clipping variant of a dependent slot over hard-overwriting it.
    preferVariants = true,

    -- Manual fallback for addon clothing that has no shop metadata.
    -- ["<component>:<collection>:<drawable>"] = {
    --     { component = "arms", collection = "", drawable = 15 },
    -- }
    forcedOverrides = {}
}

-----------------------------------------------------------------------------
-- Validation
-----------------------------------------------------------------------------
-- "clamp"  - pull invalid values to the nearest valid one
-- "reject" - discard the call and return false, reason
-- "off"    - apply blindly (the natives fail silently, expect broken peds)
Config.Validation = "reject"

-- When a collection does not exist on the ped at all (addon clothing not
-- streamed, missing DLC), fall back to the naked default instead of leaving a
-- broken component behind.
Config.FallbackToNaked = true

-----------------------------------------------------------------------------
-- Ped
-----------------------------------------------------------------------------
-- Changing the model resets health and armour. Restore them afterwards.
Config.RestoreHealth = true
Config.RestoreArmour = true

-- Milliseconds to wait for a model to stream in before giving up.
Config.ModelLoadTimeout = 10000

-----------------------------------------------------------------------------
-- Sync
-----------------------------------------------------------------------------
Config.Sync = {
    -- Components, overlays and decorations do NOT replicate reliably in FiveM.
    -- With this enabled the server keeps every appearance in a statebag so all
    -- clients render each other correctly, including after re-streaming.
    --
    -- It also makes the server-side getters synchronous - they slice the
    -- statebag instead of doing a client roundtrip.
    enabled = true,

    -- How often to retry applying a remote appearance while the ped is not
    -- streamed in yet.
    retryInterval = 500,

    -- Give up retrying after this many milliseconds.
    retryTimeout = 60000
}

-- Timeout for server -> client getter roundtrips (only used when sync is off).
Config.RequestTimeout = 5000
