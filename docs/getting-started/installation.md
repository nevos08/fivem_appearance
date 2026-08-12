# Installation

## Requirements

- FiveM server, game build **2802 or newer** (collection-based natives)
- Lua 5.4 (`lua54 'yes'`, already set in the manifest)
- No other resources. `nvx_skin` has no dependencies.

{% hint style="info" %}
The collection natives are **client-side and GTA5 only**. That is why the server never validates clothing itself - see [Multiplayer sync](../concepts/sync.md).
{% endhint %}

## Install

1. Drop `nvx_skin` into your resources folder.
2. Add it to your server config **before** anything that applies skins:

```cfg
ensure nvx_skin
```

3. Restart the server and check the console for startup errors.

## Verify

Set `Config.Debug = true` in `config.lua` and restart. That enables the test commands:

| Command                            | What it does                                                     |
| ---------------------------------- | ---------------------------------------------------------------- |
| `/nvxskin_dump`                    | Prints the current appearance as JSON                            |
| `/nvxskin_random`                  | Randomises every clothing component                              |
| `/nvxskin_set <path> <value>`      | Partial update, e.g. `/nvxskin_set components.torso.drawable 15` |
| `/nvxskin_collections <component>` | Lists collections holding drawables for that component           |

If `/nvxskin_dump` prints a full appearance table, the resource is working.

## Removing skinchanger

`nvx_skin` deliberately provides **no** skinchanger compatibility shim. Anything still calling `skinchanger:loadSkin` keeps needing `skinchanger`, so migrate those callers first - see [Migrating from skinchanger](../reference/migration.md).

## Warnings you may see on startup

`nvx_skin` guards every optional native behind an availability check rather than crashing:

```
[nvx_skin] WARN native 'GetForcedComponent' is unavailable on this build - related features are disabled
```

That means the clipping features are off on your build; everything else still works. It is not fatal.
