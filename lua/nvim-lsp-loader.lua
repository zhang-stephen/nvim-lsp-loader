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
    ---@type table
    recorder = {
        confs = {
            default = {
                path = '',
                readable = false,
                decoded = false,
            },
            user = {
                path = '',
                readable = false,
                decoded = false,
            },
        },
        loaded_servers = {},
    }
}

---@param path string the file to read/load
---@return table | nil
M.read_configuration = function(path)
    local resource = path == M.config.default_config_path and 'default' or 'user'
    M.recorder.confs[resource].path = path
    M.recorder.confs[resource].readable = util.filereadable(path)

    if not M.recorder.confs[resource].readable then
        return nil
    end

    local conf = M.loader.json_decode(io.open(path, 'r'):read('*a'))
    M.recorder.confs[resource].decoded = conf ~= nil

    return conf
end

M.setup = function(config)
    M.config = vim.tbl_extend('keep', config, M.config)

    local user_config_path = string.format('%s/.nvim/languages.json', util.resolve_work_path(M.config.root_patterns))
    local default_confs = M.read_configuration(M.config.default_config_path)
    local user_confs = M.read_configuration(user_config_path)

    if default_confs == nil then
        M.servers = user_confs and user_confs['languages']
    elseif user_confs == nil then
        M.servers = default_confs and default_confs['languages']
    else
        if M.config.mode == 'user-first' then
            M.servers = vim.tbl_extend('force', default_confs['languages'], user_confs['languages'])
        elseif M.config.mode == 'default-first' then
            M.servers = vim.tbl_extend('force', user_confs['languages'], default_confs['languages'])
        elseif M.config.mode == 'user-only' then
            M.servers = user_confs['languages']
        elseif M.config.mode == 'default-only' then
            M.servers = default_confs['languages']
        end
    end

    if M.servers == {} or M.servers == nil then
        vim.notify('No Language Server has been Configured', 'info')
        return
    end

    M.loader.load_servers(M.servers, M.config)
end

return M
