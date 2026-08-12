# Multiplayer sync

In FiveM, components, head overlays and decorations do **not** replicate reliably. Without help, other players see a ped wearing something else - usually the default outfit.

`nvx_skin` solves this with a statebag. It is on by default and can be turned off.

## How it works

1. A client applies an appearance locally and pushes it to the server.
2. The server normalizes it and writes it to `Player(src).state['nvx_skin:appearance']`, replicated.
3. Every client reacts to the statebag change and applies that appearance to the corresponding ped.

If the ped is not streamed in yet the payload is queued and retried (`Config.Sync.retryInterval`, giving up after `Config.Sync.retryTimeout`).

**The model step is skipped for remote peds.** You cannot set another client's ped model, and it replicates from the owner anyway. Everything below it does not, which is the whole point.

Because collections are resolved locally on each client, a synced outfit is also stable across players with different DLC states - precisely the case where global indices show the wrong clothes to one of them.

## Sync also makes the server fast

This is the part worth knowing when writing server code.

**With `Config.Sync.enabled = true`**, the server already holds the full appearance. Every server getter is a synchronous slice of the statebag - no round trip:

```lua
local hair = exports.nvx_skin:GetHair(src)   -- returns immediately
```

**With sync disabled**, there is nothing stored, so each getter makes a client round trip. That call is only valid inside a coroutine and returns `nil, 'timeout'` after `Config.RequestTimeout` if the client does not answer.

```lua
CreateThread(function()
    local hair, reason = exports.nvx_skin:GetHair(src)
    if not hair then
        print(('could not read hair: %s'):format(reason))   -- e.g. "timeout"
    end
end)
```

`Read(src)` always does a round trip, regardless of the setting - that is what "read fresh from the ped" means.

Setters are fire-and-forget in both cases and work either way.

## What the server does and does not validate

The server normalizes incoming appearances against the schema - it does not trust client values. But it **cannot** validate clothing: the collection natives are client-side only. Collection validity, variation ranges and clipping are all checked on the client before anything is applied.

So `exports.nvx_skin:SetComponent(src, 'torso', '', 9999, 0)` returns `true` from the server (the message was sent) while the client clamps or rejects the value. If you need the outcome, read the value back.

## Turning it off

```lua
Config.Sync.enabled = false
```

Reasonable if another resource already synchronises appearance. Consequences:

* No statebag writes.
* Server getters become round trips (see above).
* `nvx_skin:appearanceChanged` no longer fires.
* Local apply is unaffected.

The resource prints a warning on startup so this is not a silent surprise.
