Appearance = Appearance or {}

local STATE_KEY = "nvx_appearance:data"

local sync = {}
Appearance.sync = sync

-- Appearances received for players whose ped is not streamed in yet.
local pending = {}

--- Pushes the local appearance to the server, which stores it in a statebag.
--- Needed because components, overlays and decorations do NOT replicate.
function sync.push(appearance)
    if not Config.Sync.enabled then return end
    TriggerServerEvent("nvx_appearance:sync", appearance)
end

--- Applies a remote player's appearance to their ped.
---
--- The model step is skipped on purpose: you cannot set another client's ped
--- model, and it replicates from the owner anyway.
local function applyRemote(serverId, appearance)
    local playerId = GetPlayerFromServerId(serverId)
    if playerId == -1 then return false end

    local ped = GetPlayerPed(playerId)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return false end

    local normalized = Appearance.schema.normalize(appearance)
    local ok, reason = Appearance.applyTo(ped, normalized, { skipModel = true, remote = true })

    if not ok then
        Appearance.log(("remote apply for %d failed: %s"):format(serverId, reason or "?"))
    end

    return ok
end

local function queue(serverId, appearance)
    pending[serverId] = { appearance = appearance, deadline = GetGameTimer() + Config.Sync.retryTimeout }
end

CreateThread(function()
    if not Config.Sync.enabled then return end

    while true do
        Wait(Config.Sync.retryInterval)

        local now = GetGameTimer()

        for serverId, entry in pairs(pending) do
            if now > entry.deadline then
                pending[serverId] = nil
            elseif applyRemote(serverId, entry.appearance) then
                pending[serverId] = nil
            end
        end
    end
end)

CreateThread(function()
    if not Config.Sync.enabled then return end

    AddStateBagChangeHandler(STATE_KEY, nil, function(bagName, _, value)
        if type(value) ~= "table" then return end

        local serverId = tonumber(bagName:match("^player:(%d+)$"))
        if not serverId then return end

        -- Our own appearance is already applied locally.
        if serverId == GetPlayerServerId(PlayerId()) then return end

        if not applyRemote(serverId, value) then
            queue(serverId, value)
        end
    end)
end)
