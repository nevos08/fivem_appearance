Appearance = Appearance or {}

Appearance.server = {}

local RESOURCE = GetCurrentResourceName()

function Appearance.log(...)
    if not Config.Debug then return end
    print(("[%s]"):format(RESOURCE), ...)
end

function Appearance.warn(...)
    print(("[%s] ^3WARN^7"):format(RESOURCE), ...)
end

function Appearance.err(...)
    print(("[%s] ^1ERROR^7"):format(RESOURCE), ...)
end

-----------------------------------------------------------------------------
-- Request / response
-----------------------------------------------------------------------------
-- Without ox_lib there is no lib.callback, so this is the minimal equivalent:
-- an incrementing request id, a pending table and a timeout so a hung client
-- cannot leave a promise open forever.

local pending = {}
local nextId = 0

RegisterNetEvent("nvx_appearance:response", function(id, results)
    local entry = pending[id]
    if not entry then return end

    -- Only the client the request went to may answer it.
    if entry.src ~= source then return end

    pending[id] = nil
    entry.promise:resolve(results)
end)

--- Fire-and-forget call on a client.
function Appearance.call(src, action, ...)
    TriggerClientEvent("nvx_appearance:call", src, action, table.pack(...))
end

--- Round-trip call on a client. Must run inside a coroutine.
--- @return any ... the client's return values, or nil on timeout
function Appearance.request(src, action, ...)
    nextId = nextId + 1
    local id = nextId

    local p = promise.new()
    pending[id] = { promise = p, src = src }

    TriggerClientEvent("nvx_appearance:request", src, id, action, table.pack(...))

    SetTimeout(Config.RequestTimeout, function()
        local entry = pending[id]
        if entry then
            pending[id] = nil
            entry.promise:resolve(nil)
        end
    end)

    local results = Citizen.Await(p)
    if not results then return nil, "timeout" end

    return table.unpack(results, 1, results.n or #results)
end

AddEventHandler("playerDropped", function()
    local src = source
    for id, entry in pairs(pending) do
        if entry.src == src then
            pending[id] = nil
            entry.promise:resolve(nil)
        end
    end
end)
