# Collections and indices

Every clothing slot in `nvx_skin` carries a `collection` alongside its `drawable`. This is the single most important difference from older skin systems, and the reason saved outfits do not break.

## The problem with global indices

`SetPedComponentVariation` takes a **global** drawable index: a position in the flat list of every drawable for that component, across all collections. That has two failure modes:

* It is capped at **255** variations.
* When Rockstar ships a title update, the new DLC collections are inserted **before** existing ones. Every global index after them shifts. A stored outfit silently becomes different clothing.

Anything storing raw drawable numbers - skinchanger, `esx_skin`, most character creators - is exposed to this.

## Collections

The game groups drawables into named collections. Within a collection, a drawable has a **local index** that stays put across title updates, because it is relative to that collection's own start.

```lua
-- unstable                                   -- stable
SetPedComponentVariation(ped, 4, 219, 3, 0)   SetPedCollectionComponentVariation(ped, 4, 'female_heist', 9, 3, 0)
```

`nvx_skin` uses the collection form everywhere and stores the local index.

The base game collection is the **empty string** `''`. There, local and global indices happen to be identical, because no DLC collection precedes it.

```lua
exports.nvx_skin:SetComponent('torso', '', 15, 0)                  -- base game
exports.nvx_skin:SetComponent('pants', 'female_heist', 9, 3)       -- DLC
```

## Discovering what exists

```lua
-- every collection present on this ped
local collections = exports.nvx_skin:GetCollections()

-- how much is in one of them
local drawables, textures = exports.nvx_skin:GetVariationCounts('torso', 'female_heist', 4)
--    drawables = count for that component in that collection
--    textures  = count for drawable 4 specifically
```

{% hint style="info" %}
The texture count is **per drawable**. Omit the third argument and `textures` comes back as `0` - that is not an error, there is simply no drawable to count textures for.
{% endhint %}

## Converting to and from global indices

Plenty of existing resources still speak global indices. Both directions are available:

```lua
local global = exports.nvx_skin:ToGlobalIndex('torso', '', 15)
local collection, localIndex = exports.nvx_skin:FromGlobalIndex('torso', global)
```

`ToGlobalIndex` is what you hand to a legacy clothing shop. `FromGlobalIndex` is what you use to bring old data in.

## Legacy input is converted for you

If a component or prop arrives **without** a `collection` field, `nvx_skin` treats its `drawable` as a legacy global index and converts it on apply.

This happens client-side, in `client/components.lua`, not in the schema - the conversion natives need a real ped. `normalize()` only flags such entries with `legacy = true`.

The practical effect: you can feed old `users.skin` rows or existing character-creator output straight in, and the first save writes back the stable form. No data migration step.

## Validation

The collection set natives **fail silently** on an invalid index - you get an invisible or wrong ped and no error at all. So nothing is applied without being checked against these counts first.

```lua
local ok, reason = exports.nvx_skin:IsValid('torso', '', 9999, 0)
-- false, "drawable 9999 out of range (0-411) for 'torso'"
```

How invalid values are handled - clamped, refused, or passed through - is its own topic: see [Validation](validation.md).
