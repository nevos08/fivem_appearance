# Events

Events are **outbound notifications only**. They are never a control path - there is no event that changes an appearance. Use the [client](client.md) and [server](server.md) exports for that.

## `nvx_skin:applied` (client)

Fires after every successful run of the apply pipeline, local ped only.

```lua
AddEventHandler('nvx_skin:applied', function(appearance)
    print(('model %s, %d tattoos'):format(appearance.model, #appearance.tattoos))
end)
```

The table is a copy - mutating it does not affect anything.

Note that this fires for **every** change, including each scroll in a clothing shop. Debounce anything expensive.

## `nvx_skin:appearanceChanged` (server)

Fires when a client's appearance reaches the server and is written to the statebag.

```lua
AddEventHandler('nvx_skin:appearanceChanged', function(src, appearance)
    saveAppearance(src, appearance)
end)
```

{% hint style="warning" %}
Only fires while `Config.Sync.enabled` is `true`. With sync off the server never receives appearances, so this is silent - do not build persistence on it without checking that setting.
{% endhint %}

This is also the hook a framework bridge attaches to.

## Statebag

With sync enabled, each player's appearance is on their state bag under `nvx_skin:appearance`, replicated to all clients:

```lua
-- server
local appearance = Player(src).state['nvx_skin:appearance']

-- client
AddStateBagChangeHandler('nvx_skin:appearance', nil, function(bagName, _, value)
    -- ...
end)
```

Reading it is fine. Writing it directly is not - it bypasses normalization and the clients applying it, and the next real change overwrites you. Use the exports.
