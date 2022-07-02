local util = require('nvim-lsp-loader.util')

local M = {
    ---@type table<string, ...>
    config = {
        ---@type boolean just for debug, not used yet
        debug = false,
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
    },
    ---@type table
    servers = {},
    ---@type table
    loader = require('nvim-lsp-loader.loader'),
}

M.setup = function(config)
    M.config = vim.tbl_extend('keep', config, M.config)

    local json_decode = vim.fn.json_decode
    local user_config = string.format('%s/.config/nvim/languages.json', util.resolve_work_path(M.config.root_patterns))

    local default_confs = vim.fn.filereadable(M.config.default_config_path)
            and json_decode(io.open(M.config.default_config_path, 'r'):read('*a'))
        or {}
    local user_confs = vim.fn.filereadable(user_config) and json_decode(io.open(user_config, 'r'):read('*a')) or {}

    if M.config.mode == 'user-first' then
        M.servers = vim.tbl_extend('keep', default_confs['languages'], user_confs['languages'])
    elseif M.config.mode == 'default-first' then
        M.servers = vim.tbl_extend('keep', user_confs['languages'], default_confs['languages'])
    elseif M.config.mode == 'user-only' then
        M.servers = user_confs['languages']
    elseif M.config.mode == 'default-only' then
        M.servers = default_confs['languages']
    end

    if M.servers == {} or M.servers == nil then
        vim.notify('No Language Server has been Configured', 'info')
        return
    end

    M.loader.load_servers(M.servers, M.config)
end

return M
