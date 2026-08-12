# Quickstart

`nvx_skin` stores nothing. This page shows the two integrations almost every server needs: **persisting a character** and **dressing a player from another resource**.

## Save and restore a character

The appearance table is plain data - `json.encode` it and put it wherever you keep character data.

{% tabs %}
{% tab title="Server" %}
```lua
-- Saving: with Config.Sync.enabled the getter is synchronous.
local function saveAppearance(src, charId)
    local appearance = exports.nvx_skin:GetAppearance(src)
    if not appearance then return end

    MySQL.update('UPDATE characters SET appearance = ? WHERE id = ?', {
        json.encode(appearance), charId
    })
end

-- Restoring
local function loadAppearance(src, charId)
    local row = MySQL.single.await('SELECT appearance FROM characters WHERE id = ?', { charId })
    if not row?.appearance then
        -- No saved skin yet: hand the player a default and let your creator run.
        exports.nvx_skin:SetModel(src, 'mp_m_freemode_01')
        return false
    end

    exports.nvx_skin:Apply(src, json.decode(row.appearance))
    return true
end
```
{% endtab %}

{% tab title="Client" %}
```lua
-- Same thing client-side, e.g. from a character selection screen.
local ok, reason = exports.nvx_skin:Apply(appearance)

if not ok then
    print(('could not apply appearance: %s'):format(reason))
end
```
{% endtab %}
{% endtabs %}

{% hint style="warning" %}
Save what `GetAppearance` returns, not what `Read` returns. `Read` pulls from the ped via natives, and **decorations cannot be read back** - it returns `partial = true` and an empty tattoo list. Persisting that would wipe a player's tattoos. See [The appearance table](../concepts/appearance.md#reading-from-a-ped).
{% endhint %}

## React to changes

Rather than polling, hook the event that fires after every successful apply:

```lua
-- client
AddEventHandler('nvx_skin:applied', function(appearance)
    print(('appearance applied, model %s'):format(appearance.model))
end)
```

```lua
-- server, only fires while sync is enabled
AddEventHandler('nvx_skin:appearanceChanged', function(src, appearance)
    saveAppearance(src, getCharId(src))
end)
```

Autosaving straight off `nvx_skin:appearanceChanged` fires on **every** change, including each scroll in a clothing shop. Debounce it.

## Dress a player from a job script

```lua
-- A police uniform, server-side. Setters are fire-and-forget.
exports.nvx_skin:SetComponents(src, {
    torso = { collection = '', drawable = 55, texture = 0 },
    arms  = { collection = '', drawable = 41, texture = 0 },
    pants = { collection = '', drawable = 31, texture = 0 },
    shoes = { collection = '', drawable = 25, texture = 0 }
})
```

Because `arms` is passed explicitly, it wins over anything GTA would otherwise force for that top - see [Clipping and forced components](../concepts/clipping.md#precedence).

## Undress a player

```lua
exports.nvx_skin:SetNaked(src)      -- underwear, all props removed
exports.nvx_skin:ClearProp(src, 'hats')
exports.nvx_skin:ClearComponent(src, 'torso')
```

## Change one thing without touching the rest

Every setter is a partial update. Nothing else in the appearance is affected:

```lua
exports.nvx_skin:SetHairColor(src, 12, 3)
exports.nvx_skin:SetOverlay(src, 'beard', 4, 0.8, 1, 0)
exports.nvx_skin:SetFaceFeature(src, 'noseWidth', -0.4)
```
