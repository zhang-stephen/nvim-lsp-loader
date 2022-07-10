-- algorithms about json processing
-- NOTE: DO NOT import any library from neovim in this scope

local json = {}
local util = require('nvim-lsp-loader.util')

---@param data string json string to be decoded
json.decode = function(data)
    local ok, result = pcall(vim.fn.json_decode, data)
    return ok and result or nil
end

---@param t table
---@return table
json.inflate = function (t)
    local res = {}

    -- if t is list or not a table, return it directly
    if type(t) ~= 'table' or util.is_array(t) then
        return t
    end

    for key, val in pairs(t) do
        local keys = {}
        local cursor = res
        val = type(val) == 'table' and json.inflate(val) or val

        for k in string.gmatch(key, '[^.]+') do
            table.insert(keys, k)
        end

        for i, k in ipairs(keys) do
            -- for nested keys:
            -- create an empty table if cursor[k] is nil
            cursor[k] = cursor[k] ~= nil and cursor[k] or {}

            -- the cursor has arrived the deepest of the table,
            -- and the value will be assigned to the deepest key.
            if i == #keys then
                if type(val) == "table" then
                    for _1, _2 in pairs(val) do
                        cursor[k][_1] = _2
                    end
                else
                    cursor[k] = val
                end
            end

            -- move cursor to the deeper
            cursor = cursor[k]
        end
    end

    return res
end

return json