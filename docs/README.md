---
description: Ped appearance backend for FiveM - components, props, overlays, tattoos and hair fades.
---

# Overview

`nvx_skin` is the layer that applies and reads a ped's appearance. It is a **backend only** - there is no UI and no character creator. You drive it entirely through exports, from both the client and the server.

It is an alternative to resources like `skinchanger`, which cover the same job.

{% hint style="warning" %}
**It is not a 1:1 replacement.** The data format, the API and the call style are all different, and there is no compatibility shim - every caller has to be rewritten. See [Migrating from skinchanger](reference/migration.md).

It also does not replace `esx_skin`: that one additionally ships a clothing menu and persists to `users.skin`. `nvx_skin` does neither, so you keep your own UI and your own persistence - see [Quickstart](getting-started/quickstart.md).
{% endhint %}

## How it compares to skinchanger

| | skinchanger | nvx_skin |
| --- | --- | --- |
| Data format | ~130 flat keys (`tshirt_1`, `arms_2`, …) | nested, named, versioned |
| Tattoos | not supported | first-class |
| Hair fades | not supported | applied atomically with the hair |
| Clothing indices | global, capped at 255, shift on every title update | collection + local index, stable |
| Clipping | none | GTA's own forced-component data |
| Multiplayer sync | none | statebags, optional |
| Validation | none | native-backed, clamp or reject |
| Framework | hard ESX dependency | none |

## Design decisions

**No dependencies.** No ox_lib, no ESX, no oxmysql. Framework bridges are a separate concern and live outside this resource.

**No persistence.** `nvx_skin` never touches a database. It holds the current appearance in memory and, if sync is on, in a statebag. Saving and loading is your resource's job - see [Quickstart](getting-started/quickstart.md).

**Exports only.** Events exist purely as outbound hooks, never as a control path. There is no `TriggerEvent('nvx_skin:loadSkin', …)`.

**The game is the source of truth.** Variation counts, validity, and which arms belong to which top all come from natives at runtime, not from a hand-maintained table that rots with every DLC.

## A quick taste

```lua
-- client
exports.nvx_skin:SetComponent('torso', '', 15, 0)
local hair = exports.nvx_skin:GetHair()

-- server
exports.nvx_skin:SetComponent(source, 'torso', '', 15, 0)
local appearance = exports.nvx_skin:GetAppearance(source)
```

## Where to go next

* [Installation](getting-started/installation.md) - drop it in and check it runs
* [Quickstart](getting-started/quickstart.md) - save and restore a character
* [The appearance table](concepts/appearance.md) - the format everything hangs on
* [Client exports](api/client.md) / [Server exports](api/server.md) - the full surface
