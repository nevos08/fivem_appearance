Appearance = Appearance or {}

local path = {}
Appearance.path = path

--- Splits "components.torso.drawable" into { "components", "torso", "drawable" }.
--- Numeric segments stay strings here; resolution tries both.
local function split(str)
    local parts = {}
    for part in string.gmatch(str, "[^%.]+") do
        parts[#parts + 1] = part
    end
    return parts
end

--- Reads a nested value by dotted path. Returns nil when any segment is missing.
--- @param tbl table
--- @param str string|nil dotted path, nil returns tbl itself
function path.get(tbl, str)
    if not str or str == "" then return tbl end
    if type(tbl) ~= "table" then return nil end

    local parts = split(str)
    local node = tbl

    for i = 1, #parts do
        if type(node) ~= "table" then return nil end

        local key = parts[i]
        local value = node[key]

        -- Tables keyed by number (component ids, face feature indices) are still
        -- addressable through the string path.
        if value == nil then
            local numeric = tonumber(key)
            if numeric then value = node[numeric] end
        end

        if value == nil then return nil end
        node = value
    end

    return node
end

--- Writes a nested value by dotted path, creating intermediate tables.
function path.set(tbl, str, value)
    if not str or str == "" then return false end
    if type(tbl) ~= "table" then return false end

    local parts = split(str)
    local node = tbl

    for i = 1, #parts - 1 do
        local key = parts[i]
        local nxt = node[key]

        if nxt == nil then
            local numeric = tonumber(key)
            if numeric and node[numeric] ~= nil then
                key = numeric
                nxt = node[numeric]
            else
                nxt = {}
                node[key] = nxt
            end
        end

        if type(nxt) ~= "table" then return false end
        node = nxt
    end

    local last = parts[#parts]
    if node[last] == nil and tonumber(last) and node[tonumber(last)] ~= nil then
        last = tonumber(last)
    end

    node[last] = value
    return true
end

--- Deep copy. Every getter hands out copies so callers cannot mutate the cache.
function path.copy(value)
    if type(value) ~= "table" then return value end

    local out = {}
    for k, v in pairs(value) do
        out[k] = path.copy(v)
    end
    return out
end

--- Recursively merges `src` into `dst` (in place). Arrays are replaced, not
--- merged - a tattoo list is a value, not something to append to.
function path.merge(dst, src)
    if type(src) ~= "table" then return src end

    for k, v in pairs(src) do
        if type(v) == "table" and type(dst[k]) == "table" and not v[1] then
            path.merge(dst[k], v)
        else
            dst[k] = path.copy(v)
        end
    end

    return dst
end
