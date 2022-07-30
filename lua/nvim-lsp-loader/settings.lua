local DEFAULT_SETTINGS = {
    ---@type boolean just for debug, not used yet
    debug = false,
    ---@type boolean
    nested_json_keys = false,
    ---@type boolean
    auto_update = false,
    ---@type string ~/.config/nvim/languages.json
    default_config_path = vim.fn.stdpath('config') .. '/languages.json',
    ---@type table<string>
    root_patterns = {
        '.git/',
    },
    ---@type function | nil
    on_attach = nil,
    ---@type function | nil
    make_capabilities = nil,
    ---@type function | nil
    server_config_cb = nil,
    ---@type string
    mode = 'user-first',
}

local settings = {
    current = DEFAULT_SETTINGS,
}

settings.resolve = function(user_conf)
    settings.current = vim.tbl_extend('keep', user_conf, DEFAULT_SETTINGS)
    return settings.current
end

return settings
