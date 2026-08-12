# Clipping and forced components

Not every top works with every pair of arms. Wear the wrong combination and hands poke through sleeves, or a shirt collar clips through a jacket. GTA solves this with data it ships itself, and `nvx_appearance` reads that data at runtime.

## Where the data comes from

Every purchasable clothing item has an entry in `SHOP_CLOTHES.meta` carrying a `forcedComponentList`, `restrictionTags` and variant lists. That is exactly what the in-game clothing store uses to avoid clipping.

`nvx_appearance` reads it through the shop apparel natives:

1. `GetHashNameForComponent(ped, componentId, drawable, texture)` → the item's unique hash
2. `GetShopPedApparelForcedComponentCount(hash)` → how many companion slots it forces
3. `GetForcedComponent(hash, i)` → `nameHash, enumValue, componentType`

`componentType` is the PV\_COMP slot - `3` = `UPPR` (arms), `8` = `ACCS` (undershirt), `11` = `JBIB` (top). `enumValue` is the drawable to force. That pair is literally "these arms belong to this top".

Variants (`GetVariantComponent`) are the softer form: alternative, non-clipping versions of another slot rather than a hard override.

{% hint style="success" %}
This is neither a hand-curated rule set nor blind guessing - it is Rockstar's own data, so it stays correct when new DLC ships.
{% endhint %}

## It happens automatically

With `Config.Clothing.applyForcedComponents` on (the default), setting a top pulls its arms and undershirt along:

```lua
exports.nvx_appearance:SetComponent('torso', '', 47, 0)
-- arms and shirt are set to whatever GTA says belongs to drawable 47
```

## Precedence

**Explicitly supplied slots always win.** Only slots you did *not* pass get filled from the forced data:

```lua
-- arms is explicit -> the forced arms are ignored
exports.nvx_appearance:SetComponents({
    torso = { collection = '', drawable = 47, texture = 0 },
    arms  = { collection = '', drawable = 15, texture = 0 }
})
```

Without that rule you could never deliberately deviate - which job uniforms and roleplay outfits regularly need to.

## Inspecting it yourself

Useful when building a clothing shop or character creator:

```lua
local slot = exports.nvx_appearance:GetComponent('torso')

local hash = exports.nvx_appearance:GetItemHash('torso', slot.collection, slot.drawable, slot.texture)
local forced = exports.nvx_appearance:GetForcedComponents('torso', slot.collection, slot.drawable, slot.texture)
local variants = exports.nvx_appearance:GetVariants('torso', slot.collection, slot.drawable, slot.texture)

-- forced = { { component = 'arms', collection = '', drawable = 15, texture = 0 }, ... }
```

`ResolveOutfit` answers "what would this outfit actually look like" without applying anything - built for previews:

```lua
local components, props = exports.nvx_appearance:ResolveOutfit({
    torso = { collection = '', drawable = 47, texture = 0 }
})
```

## Where it stops

**Only shop items have this data.** Job outfits, non-purchasable variants and most addon clothing have no entry - `GetItemHash` returns `0` and nothing happens. No fallback, no guessing.

For addon clothing you can fill the gap manually:

```lua
Config.Clothing.forcedOverrides = {
    ['torso::120'] = {                  -- "<component>:<collection>:<drawable>"
        { component = 'arms',  collection = '', drawable = 15 },
        { component = 'shirt', collection = '', drawable = 15 }
    }
}
```

**Forced entries of type 10 (`PV_COMP_DECL`) are skipped.** There `enumValue` is a decoration preset hash, not a drawable index - writing it into the `badge` slot would clamp a 32-bit hash down to an arbitrary decal. Decorations belong to the decoration step.

**The `.ymt` layer is not reachable.** `CPedVariationInfo` flags (`PV_FLAG_BULKY`, `PV_FLAG_ARMOURED`, …) are not exposed by any native. They mostly describe context - bulky, armoured, not-in-car - rather than clipping pairs, so little is lost.

Finally: this prevents combinations Rockstar did not intend. It is not a promise that nothing ever clips - a handful of vanilla combinations have flaws of their own.

## Restricting the choices instead

Everything above corrects an outfit after the fact. A character creator can use the same data the other way round - only offering the arms that fit the chosen top - by filtering its catalog on `GetItemHash` and `GetForcedComponents`. `nvx_appearance` deliberately ships no catalog layer for that; it belongs in the creator.
