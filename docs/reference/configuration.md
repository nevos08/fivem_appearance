# Configuration

Everything lives in `config.lua`.

## General

| Key | Default | Description |
| --- | --- | --- |
| `Config.Debug` | `false` | Verbose logging for every apply, clamp and sync event |
| `Config.Locale` | `'de'` | Locale for log messages, falls back to `en` |
| `Config.DebugCommands` | `true` | Registers the `/nvxskin_*` commands. Requires `Config.Debug` |

## Head blend

```lua
Config.HeadBlend = {
    linkSkinToParents = true,
    linkSkinMix = false
}
```

| Key | Description |
| --- | --- |
| `linkSkinToParents` | `skinFirst`/`skinSecond` follow `shapeFirst`/`shapeSecond` |
| `linkSkinMix` | `skinMix` additionally follows `shapeMix` |

The coupling is applied on write, not on apply. Both fields stay in the schema and are always stored - see [The appearance table](../concepts/appearance.md#skin-parents-can-follow-shape-parents).

## Clothing

```lua
Config.Clothing = {
    applyForcedComponents = true,
    applyForcedProps = true,
    preferVariants = true,
    forcedOverrides = {}
}
```

| Key | Description |
| --- | --- |
| `applyForcedComponents` | Pull the matching arms/undershirt from GTA's data when a top is set |
| `applyForcedProps` | Same for props |
| `preferVariants` | Prefer a non-clipping variant over a hard overwrite |
| `forcedOverrides` | Manual rules for addon clothing that has no shop metadata |

See [Clipping and forced components](../concepts/clipping.md).

## Validation

| Key | Default | Description |
| --- | --- | --- |
| `Config.Validation` | `'clamp'` | `'clamp'`, `'reject'` or `'off'` |
| `Config.FallbackToNaked` | `true` | Fall back to the naked default when a collection is missing entirely |

`'off'` is not recommended: the set natives fail silently, so invalid values produce an invisible ped with no error.

Full behaviour of each mode, what gets checked, and how clamped values are written back: [Validation](../concepts/validation.md).

## Ped

| Key | Default | Description |
| --- | --- | --- |
| `Config.RestoreHealth` | `true` | Restore health after a model change |
| `Config.RestoreArmour` | `true` | Restore armour after a model change |
| `Config.ModelLoadTimeout` | `10000` | Milliseconds to wait for a model to stream in |

## Sync

```lua
Config.Sync = {
    enabled = true,
    retryInterval = 500,
    retryTimeout = 60000
}

Config.RequestTimeout = 5000
```

| Key | Description |
| --- | --- |
| `Sync.enabled` | Statebag sync. Also makes server getters synchronous |
| `Sync.retryInterval` | How often to retry a remote apply while the ped is not streamed |
| `Sync.retryTimeout` | Give up retrying after this long |
| `RequestTimeout` | Timeout for server → client getter round trips (only used when sync is off) |

See [Multiplayer sync](../concepts/sync.md).
