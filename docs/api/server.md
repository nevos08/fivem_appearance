# Server exports

The server mirrors the client API with `src` as the first argument.

```lua
exports.nvx_skin:SetComponent(src, 'torso', '', 15, 0)
local hair = exports.nvx_skin:GetHair(src)
```

## Setters

Fire-and-forget: they route to the target client, which owns the natives. They return `true` once the message is sent - **not** confirmation that it applied. They work whether or not sync is enabled.

`Apply` `Update` `Reset` `SetNaked` `SetModel` `SetHeadBlend` `SetFaceFeature` `SetFaceFeatures` `SetOverlay` `SetOverlays` `SetEyeColor` `SetHair` `SetHairStyle` `SetHairColor` `SetHairFade` `SetComponent` `SetComponents` `ClearComponent` `SetProp` `SetProps` `ClearProp` `SetTattoos` `AddTattoo` `RemoveTattoo` `ClearTattoos`

Arguments are identical to the [client versions](client.md), shifted by one.

{% hint style="warning" %}
The server cannot validate clothing - the collection natives are client-side only. A setter with an out-of-range drawable still returns `true`; the client clamps or rejects it. Read the value back if the outcome matters.
{% endhint %}

## Getters

`GetAppearance` `Get` `GetModel` `GetSex` `IsFreemode` `GetHeadBlend` `GetFaceFeature` `GetFaceFeatures` `GetOverlay` `GetOverlays` `GetEyeColor` `GetHair` `GetHairStyle` `GetHairColor` `GetHairFade` `GetComponent` `GetComponents` `GetProp` `GetProps` `GetTattoos` `HasTattoo` `Read`

Their timing depends on one setting:

| `Config.Sync.enabled` | Behaviour |
| --- | --- |
| `true` (default) | Synchronous slice of the statebag, no round trip |
| `false` | Client round trip - **must run inside a coroutine**, returns `nil, 'timeout'` after `Config.RequestTimeout` |

`Read(src)` always makes a round trip and returns `appearance, partial`.

```lua
-- safe under both settings
CreateThread(function()
    local appearance, reason = exports.nvx_skin:GetAppearance(src)
    if not appearance then
        print(('no appearance: %s'):format(reason))   -- "timeout" or "no appearance stored"
    end
end)
```

With sync on and nothing stored yet - the player has not applied a skin - getters return `nil, 'no appearance stored'`.

## Not available on the server

`IsValid` `GetVariationCounts` `GetCollections` `ToGlobalIndex` `FromGlobalIndex` `GetItemHash` `GetForcedComponents` `GetForcedProps` `GetVariants` `ResolveOutfit`

All of these sit on client-only natives. A server-side stub would have to lie about the result, so there is none.

## Example: a job uniform

```lua
RegisterNetEvent('myjob:changeIntoUniform', function()
    local src = source

    exports.nvx_skin:SetComponents(src, {
        torso = { collection = '', drawable = 55, texture = 0 },
        arms  = { collection = '', drawable = 41, texture = 0 },
        pants = { collection = '', drawable = 31, texture = 0 },
        shoes = { collection = '', drawable = 25, texture = 0 }
    })

    exports.nvx_skin:ClearProp(src, 'hats')
end)
```
