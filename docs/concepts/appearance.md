# The appearance table

Everything in `nvx_skin` is one versioned table. It is plain data - safe to `json.encode`, store, and hand back later.

```lua
{
    version = 1,
    model   = 'mp_m_freemode_01',       -- string or hash

    headBlend = {
        shapeFirst = 0, shapeSecond = 21,   -- face parents
        skinFirst  = 0, skinSecond  = 21,   -- skin tone parents
        shapeMix = 0.5, skinMix = 0.5       -- 0.0 - 1.0
    },

    faceFeatures = { noseWidth = 0.0, ... },        -- 20 named values, -1.0 - 1.0

    headOverlays = {
        beard = { style = 255, opacity = 0.0, colorType = 1, color = 0, secondColor = 0 },
        ...                                          -- 12 named overlays
    },

    eyeColor = 0,

    hair = {
        collection = '', drawable = 0, texture = 0,
        color = 0, highlight = 0,
        fade = nil                                   -- see below
    },

    components = {
        torso = { collection = '', drawable = 15, texture = 0, palette = 0 },
        ...                                          -- 10 named slots
    },

    props = {
        hats = { collection = '', drawable = -1, texture = 0 },
        ...                                          -- 5 named slots
    },

    tattoos = {
        { collection = 'mpairraces_overlays',
          male = 'MP_Airraces_Tattoo_000_M', female = 'MP_Airraces_Tattoo_000_F' }
    }
}
```

## Named slots

| Components | Props | Head overlays |
| --- | --- | --- |
| `mask` `arms` `pants` `bags` `shoes` `accessory` `shirt` `armor` `badge` `torso` | `hats` `glasses` `ears` `watches` `bracelets` | `blemishes` `beard` `eyebrows` `ageing` `makeUp` `blush` `complexion` `sunDamage` `lipstick` `moleAndFreckles` `chestHair` `bodyBlemishes` |

Every export that takes a slot accepts **either** the name or the numeric id: `SetComponent('torso', …)` and `SetComponent(11, …)` are the same call.

{% hint style="warning" %}
Prefer names. Numeric ids are ambiguous between components and props - `1` is both `mask` and `glasses`, `6` is both `shoes` and `watches`. Components win.
{% endhint %}

Hair is **not** a component slot. It has its own subsystem because the fade travels with it, and is addressed as `'hair'` in the query exports (`GetVariationCounts`, `IsValid`, `ToGlobalIndex`, `FromGlobalIndex`).

## Native scales, no conversions

Values are exactly what the natives expect. There are no `*10` / `*100` / `/10` conventions like in skinchanger:

| Field | Range |
| --- | --- |
| `faceFeatures.*` | `-1.0` to `1.0` |
| `headBlend.shapeMix` / `skinMix` | `0.0` to `1.0` |
| `headOverlays.*.opacity` | `0.0` to `1.0` |
| `headOverlays.*.style` | `0`+, or **`255` for "no overlay"** (not `-1`) |
| `props.*.drawable` | `0`+, or **`-1` for "no prop"** |

`colorType` selects the palette: `1` = hair colours (beard, eyebrows, chest hair), `2` = makeup palette (make-up, blush, lipstick), `0` = no colour. It is filled in for you and rarely needs setting.

## The third parent is not in the schema

`SetPedHeadBlendData` takes a third parent and a `thirdMix`. `nvx_skin` fixes those at `0` / `0.0` and does not expose them.

## Skin parents can follow shape parents

`Config.HeadBlend.linkSkinToParents` (on by default) makes `skinFirst`/`skinSecond` mirror `shapeFirst`/`shapeSecond`, because a skin tone that does not match the face is rarely what you want.

The coupling is applied **on write**, in `normalize()`. Both fields are always present and always stored - turning the option off later frees them again immediately, and an appearance created with it off keeps its deviating skin tones until something writes to it.

## Hair fade

`hair.fade` has three states:

| Value | Meaning |
| --- | --- |
| `nil` | Use the default fade for this hair style |
| `false` | No fade |
| `{ collection = …, overlay = … }` | Explicit override |

Because a partial update cannot carry `nil` (a key set to `nil` simply is not in the table), pass **`true`** or `'auto'` to clear an override:

```lua
exports.nvx_skin:SetHairFade(false)   -- off
exports.nvx_skin:SetHairFade(true)    -- back to the per-style default
```

## Tattoos

A tattoo is the minimal triple `{ collection, male, female }`. Both hashes are stored so a **gender change keeps the tattoo** rather than dropping or mismatching it.

`nvx_skin` has no tattoo catalog on purpose. Labels, zones and previews are UI concerns and belong in your character creator; the skin only carries what is needed to apply it.

## Reading from a ped

`Read(ped?)` reconstructs an appearance from the ped using natives, ignoring the cache. It returns `appearance, partial`.

```lua
local appearance, partial = exports.nvx_skin:Read()
```

**Decorations cannot be read back** - no native enumerates them. When `nvx_skin` has no cached appearance to carry them over from, `partial` is `true` and `tattoos` is empty. Never persist a `partial = true` result over a good one.
