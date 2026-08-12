# Validation

## Why it exists

The collection set natives **fail silently**. Give `SetPedCollectionComponentVariation` a drawable that does not exist and it returns nothing, logs nothing, and leaves you with an invisible or wrong-looking ped. There is no error to catch.

That is the single most common way a skin system breaks in a way nobody can debug. So `nvx_appearance` never hands a value to those natives without checking it first.

## The three modes

```lua
Config.Validation = "clamp"   -- "clamp" | "reject" | "off"
```

| Mode | What happens to an invalid value |
| --- | --- |
| `"clamp"` (default) | Pulled to the nearest valid value and applied |
| `"reject"` | **Nothing is applied.** The call returns `false, reason` |
| `"off"` | Passed straight through to the natives |

Worked example - `torso` has 412 drawables in the base collection:

```lua
local ok, reason = exports.nvx_appearance:SetComponent('torso', '', 9999, 0)
```

| Mode | `ok` | `reason` | Ped |
| --- | --- | --- | --- |
| `clamp` | `true` | – | wears drawable `411` |
| `reject` | `false` | `component 'torso': drawable 9999 out of range (0-411) for 'torso'` | unchanged |
| `off` | `true` | – | invisible |

## What gets checked

In order, for every component, prop and the hair:

1. **Does the collection exist on this ped?** Addon clothing that is not streamed, or a missing DLC, fails here. See [FallbackToNaked](#fallbacktonaked) below.
2. **Is `drawable` within `0 … GetNumberOfPedCollectionDrawableVariations - 1`?**
3. **Is `texture` within the range for *that* drawable?** Texture counts are per-drawable, not per-component.
4. **Does `IsPedCollectionComponentVariationValid` accept the combination?** Some drawable/texture pairs are invalid even when both are in range. In `clamp` mode the remaining textures of that drawable are tried before giving up.

Props are the exception: `drawable = -1` means "no prop" and is always valid.

With `Config.Debug` on, a Gen9-exclusive item additionally logs a warning - it will not render for clients on an older build.

## Clamped values are written back

This is the part that matters for persistence. After a clamp, the **cache holds what the ped actually wears**, not what you asked for:

```lua
exports.nvx_appearance:SetComponent('torso', '', 9999, 0)
exports.nvx_appearance:GetComponent('torso').drawable   --> 411, not 9999
```

So a saved appearance never contains a value the game rejected, and the synced statebag never pushes a broken value to other clients.

## Reject applies nothing at all

In `reject` mode the whole set is validated **before** anything is written. One bad slot means no slot is applied - you never end up with a half-changed ped from input that was supposed to be refused.

```lua
local ok, reason = exports.nvx_appearance:SetComponents({
    torso = { collection = '', drawable = 5,    texture = 0 },   -- fine
    pants = { collection = '', drawable = 9999, texture = 0 }    -- invalid
})
-- ok = false: neither torso nor pants was applied, the cache is untouched
```

{% hint style="info" %}
`clamp` can still fail - if a drawable has no valid texture at all, or a collection is missing while `FallbackToNaked` is off. Those also come back as `false, reason`.
{% endhint %}

## FallbackToNaked

```lua
Config.FallbackToNaked = true
```

A separate safety net, and it only applies to check 1 above. When a collection is not on the ped at all, the slot falls back to the naked default from `NAKED_DATA` instead of leaving something broken behind. With `false` you get `false, reason` instead.

This is what keeps a player from turning invisible after you remove an addon clothing pack that their saved outfit still references.

## Checking without applying

```lua
local ok, reason = exports.nvx_appearance:IsValid('torso', '', 9999, 0)
-- false, "drawable 9999 out of range (0-411) for 'torso'"
```

`IsValid` reports whether the value is valid **exactly as given**. Under `clamp` a value that would be corrected still returns `false` with `"value was corrected"` - the point of the export is to tell you the input was wrong, not what the resource would make of it.

Use it when building a clothing shop or character creator, together with [`GetVariationCounts`](collections.md#discovering-what-exists).

## The server cannot validate

The collection natives are **client-side only**. A server-side setter therefore returns `true` as soon as the message is sent - that is not confirmation that the value was accepted:

```lua
exports.nvx_appearance:SetComponent(src, 'torso', '', 9999, 0)   --> true, always
```

The client still validates before applying. If the outcome matters, read the value back:

```lua
CreateThread(function()
    exports.nvx_appearance:SetComponent(src, 'torso', '', 9999, 0)
    Wait(200)
    local slot = exports.nvx_appearance:GetComponent(src, 'torso')
    print(slot.drawable)   -- what actually got applied
end)
```

See [Multiplayer sync](sync.md#what-the-server-does-and-does-not-validate).

## Which mode to use

**`clamp`** for production. A player never gets stuck with an invisible character, and stored outfits self-heal when a DLC or an addon pack changes.

**`reject`** while building a clothing shop or character creator. It surfaces bad indices in your own code instead of quietly correcting them, which is exactly what you want during development.

**`off`** only to prove a validation bug is not the cause of something. Never in production - the natives give you no error, so a broken ped has no trace at all.
