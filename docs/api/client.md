# Client exports

All calls go through `exports.nvx_appearance` and act on the **local ped**.

Setters return `ok, reason`. Getters return **copies** - mutating a returned table cannot corrupt the internal cache.

Slot arguments accept a name or a numeric id; `collection` may be `nil`, meaning the base game collection.

## Whole appearance

| Export | Description |
| --- | --- |
| `Apply(appearance, opts?)` | Runs the full pipeline. `ok, reason` |
| `Update(partial)` | Deep-merges a partial and re-applies only what is affected |
| `GetAppearance()` | The whole table |
| `Read(ped?)` | Reads from the ped via natives. `appearance, partial` |
| `Get(path)` | Escape hatch for dotted paths, e.g. `'hair.fade.overlay'` |
| `Reset()` | Schema default for the current sex |
| `SetNaked()` | Underwear, all props removed |

```lua
exports.nvx_appearance:Apply(appearance)
exports.nvx_appearance:Update({ hair = { color = 12 } })
local drawable = exports.nvx_appearance:Get('components.torso.drawable')
```

## Model

| Export | Description |
| --- | --- |
| `SetModel(model)` | String or hash |
| `GetModel()` | |
| `GetSex()` | `'male'`, `'female'`, or `nil` for non-freemode peds |
| `IsFreemode()` | |

A model change resets components, overlays **and decorations**, so the whole appearance is re-applied afterwards. Health and armour are restored (`Config.RestoreHealth` / `RestoreArmour`).

## Head

| Export | Description |
| --- | --- |
| `SetHeadBlend(blend)` / `GetHeadBlend()` | `{ shapeFirst, shapeSecond, skinFirst, skinSecond, shapeMix, skinMix }` |
| `SetFaceFeature(nameOrIndex, value)` / `GetFaceFeature(nameOrIndex)` | `-1.0` to `1.0` |
| `SetFaceFeatures(tbl)` / `GetFaceFeatures()` | All 20 at once |
| `SetOverlay(nameOrId, style, opacity, color, secondColor)` | `style = 255` is off |
| `GetOverlay(nameOrId)` | `{ style, opacity, colorType, color, secondColor }` |
| `SetOverlays(tbl)` / `GetOverlays()` | |
| `SetEyeColor(color)` / `GetEyeColor()` | |

```lua
exports.nvx_appearance:SetOverlay('beard', 4, 0.8, 1, 0)
exports.nvx_appearance:SetFaceFeature('noseWidth', -0.4)
```

## Hair

The fade is always carried along with the style.

| Export | Description |
| --- | --- |
| `SetHair(collection, drawable, texture, color, highlight, fade)` | Everything at once |
| `GetHair()` | `{ collection, drawable, texture, color, highlight, fade }` |
| `SetHairStyle(collection, drawable, texture)` / `GetHairStyle()` | Returns three values |
| `SetHairColor(color, highlight)` / `GetHairColor()` | Returns two values |
| `SetHairFade(fade)` / `GetHairFade()` | `false` = off, `true`/`'auto'` = per-style default, table = override |

```lua
exports.nvx_appearance:SetHairStyle('', 7, 0)
exports.nvx_appearance:SetHairFade(false)
```

## Clothing

| Export | Description |
| --- | --- |
| `SetComponent(nameOrId, collection, drawable, texture, palette)` | |
| `GetComponent(nameOrId)` | `{ collection, drawable, texture, palette }` |
| `SetComponents(tbl)` / `GetComponents()` | |
| `ClearComponent(nameOrId)` | Back to the naked default |
| `SetProp(nameOrId, collection, drawable, texture)` | `drawable = -1` removes it |
| `GetProp(nameOrId)` | `{ collection, drawable, texture }` |
| `SetProps(tbl)` / `GetProps()` | |
| `ClearProp(nameOrId)` | |

Slots passed here are treated as explicit and win over forced components - see [Clipping](../concepts/clipping.md#precedence).

## Tattoos

| Export | Description |
| --- | --- |
| `SetTattoos(list)` / `GetTattoos()` | |
| `AddTattoo(t)` | No-op if already present |
| `RemoveTattoo(t)` | `false, reason` if not present |
| `HasTattoo(t)` | |
| `ClearTattoos()` | |

```lua
exports.nvx_appearance:AddTattoo({
    collection = 'mpairraces_overlays',
    male = 'MP_Airraces_Tattoo_000_M',
    female = 'MP_Airraces_Tattoo_000_F'
})
```

## Collections and validation

| Export | Description |
| --- | --- |
| `GetCollections()` | Every collection on this ped |
| `GetVariationCounts(nameOrId, collection, drawable?)` | `drawables, textures` - textures need the drawable |
| `IsValid(nameOrId, collection, drawable, texture)` | `ok, reason` |
| `ToGlobalIndex(nameOrId, collection, drawable)` | For legacy interop |
| `FromGlobalIndex(nameOrId, globalDrawable)` | `collection, localIndex` |

Hair is addressed as `'hair'` in these four.

## Clipping

| Export | Description |
| --- | --- |
| `GetItemHash(nameOrId, collection, drawable, texture)` | `0` = not a shop item |
| `GetForcedComponents(nameOrId, collection, drawable, texture)` | |
| `GetForcedProps(...)` | |
| `GetVariants(...)` | Non-clipping alternatives |
| `ResolveOutfit(components)` | `components, props` - resolves without applying |

See [Clipping and forced components](../concepts/clipping.md).
