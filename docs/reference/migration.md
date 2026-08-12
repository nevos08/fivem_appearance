# Migrating from skinchanger

`nvx_skin` ships **no** compatibility shim. Old calls do not work against it - they have to be rewritten. The data, however, migrates itself.

## Data migrates automatically

`normalize()` accepts the legacy shapes as input, so you can feed existing rows straight in:

* **`sex = 'male'`** → the matching freemode model
* **`father` / `mother`** → `shapeFirst` / `shapeSecond`
* **Scaled values** → native scales. Face features `-10…10` → `-1.0…1.0`, mix `0…100` → `0.0…1.0`, opacity `0…10` → `0.0…1.0`
* **`hair.style`** → `hair.drawable`
* **Zone-keyed tattoos** with `hashMale` / `hashFemale` → the flat `{ collection, male, female }` list, UI metadata dropped
* **Missing `collection`** → the drawable is treated as a legacy global index and converted on apply

So this works without a migration script:

```lua
local legacy = json.decode(row.skin)          -- old users.skin, or charcreator output
exports.nvx_skin:Apply(src, legacy)
```

The first save writes the modern form back. Migrating the database is optional - you can let it happen as players log in.

{% hint style="info" %}
Scale detection is a heuristic: a face feature outside `-1.0…1.0` is assumed to be on the old scale. Values already in native scale pass through untouched.
{% endhint %}

## Call sites have to change

| Old | New |
| --- | --- |
| `TriggerEvent('skinchanger:loadSkin', skin)` | `exports.nvx_skin:Apply(skin)` |
| `TriggerEvent('skinchanger:getSkin', cb)` | `local skin = exports.nvx_skin:GetAppearance()` |
| `TriggerEvent('skinchanger:loadClothes', skin, clothes)` | `exports.nvx_skin:SetComponents(components)` |
| `TriggerEvent('skinchanger:change', key, val)` | The matching setter, e.g. `SetComponent` |
| `exports['skinchanger']:GetSkin()` | `exports.nvx_skin:GetAppearance()` |
| `TriggerServerEvent('esx_skin:save', skin)` | Your own persistence - `nvx_skin` stores nothing |

The callback style is gone. Getters return directly on the client, and on the server they are synchronous while sync is enabled.

## Key mapping

The flat skinchanger keys map onto named slots. `_1` was the drawable, `_2` the texture:

| skinchanger | nvx\_skin |
| --- | --- |
| `tshirt_1` / `tshirt_2` | `components.shirt.drawable` / `.texture` |
| `torso_1` / `torso_2` | `components.arms.*` |
| `arms` / `arms_2` | `components.arms.*` |
| `pants_1` / `pants_2` | `components.pants.*` |
| `shoes_1` / `shoes_2` | `components.shoes.*` |
| `mask_1` / `mask_2` | `components.mask.*` |
| `bproof_1` / `bproof_2` | `components.armor.*` |
| `chain_1` / `chain_2` | `components.accessory.*` |
| `decals_1` / `decals_2` | `components.badge.*` |
| `bags_1` / `bags_2` | `components.bags.*` |
| `helmet_1` / `helmet_2` | `props.hats.*` |
| `glasses_1` / `glasses_2` | `props.glasses.*` |
| `ears_1` / `ears_2` | `props.ears.*` |
| `watches_1` / `watches_2` | `props.watches.*` |
| `bracelets_1` / `bracelets_2` | `props.bracelets.*` |
| `hair_1` / `hair_2` | `hair.drawable` / `hair.texture` |
| `hair_color_1` / `hair_color_2` | `hair.color` / `hair.highlight` |
| `eye_color` | `eyeColor` |
| `beard_1` … `beard_4` | `headOverlays.beard.{style,opacity,color}` |
| `mom` / `dad` | `headBlend.shapeSecond` / `shapeFirst` |
| `face_md_weight` / `skin_md_weight` | `headBlend.shapeMix` / `skinMix` |

{% hint style="warning" %}
Watch `torso_1` and `arms`. In skinchanger both refer to component 3, which `nvx_skin` calls `arms`. The name `torso` here is component **11** - the top. Getting these two confused is the usual migration bug.
{% endhint %}

## What you gain

Things skinchanger simply could not do:

* Tattoos and hair fades, applied in the right order so a model change does not drop them
* Outfits that survive title updates ([Collections](../concepts/collections.md))
* Arms and undershirts that match the top ([Clipping](../concepts/clipping.md))
* Other players actually seeing your clothes ([Sync](../concepts/sync.md))
