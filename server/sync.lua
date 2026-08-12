Skin = Skin or {}

local STATE_KEY = "nvx_skin:appearance"

local sync = {}
Skin.serverSync = sync

sync.key = STATE_KEY

--- Whether the statebag is in use. When it is, the server-side getters are
--- synchronous - they slice the state instead of doing a client roundtrip.
function sync.enabled()
    return Config.Sync.enabled == true
end

--- The stored appearance for a player, or nil.
function sync.get(src)
    if not sync.enabled() then return nil end

    local player = Player(src)
    if not player then return nil end

    return player.state[STATE_KEY]
end

function sync.set(src, appearance)
    if not sync.enabled() then return end

    local player = Player(src)
    if not player then return end

    player.state:set(STATE_KEY, appearance, true)
end

--- Client reports its appearance. It is normalized here rather than trusted -
--- collection validity cannot be checked server-side (those natives are
--- client-only), so this is schema validation, not clothing validation.
RegisterNetEvent("nvx_skin:sync", function(appearance)
    local src = source
    if not sync.enabled() then return end

    local normalized = Skin.schema.normalize(appearance)
    sync.set(src, normalized)

    TriggerEvent("nvx_skin:appearanceChanged", src, normalized)
    Skin.log(("stored appearance for %d"):format(src))
end)
