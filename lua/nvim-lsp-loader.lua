local util = require('nvim-lsp-loader.util')

local M = {
    ---@type table<string, ...>
    config = {},
    ---@type table
    servers = {},
    ---@type table
    loader = require('nvim-lsp-loader.loader'),
    ---@type table
    json = require('nvim-lsp-loader.json'),
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
    },
}

---@param resource string one of default and user
---@return table
M.get_recorder = function(resource)
    return M.recorder.confs[resource]
end

---@param path string the file to read/load
---@return table | nil
M.read_configuration = function(path)
    local resource = path == M.config.default_config_path and 'default' or 'user'
    M.get_recorder(resource).path = path
    M.get_recorder(resource).readable = util.filereadable(path)

    if not M.get_recorder(resource).readable then
        return nil
    end

    local conf = M.json.decode(io.open(path, 'r'):read('*a'))
    M.recorder.confs[resource].decoded = conf ~= nil

    if M.config.nested_json_keys and M.get_recorder(resource).decoded then
        conf = M.json.inflate(conf)
    end

    return conf
end

M.setup = function(config)
    M.config = require('nvim-lsp-loader.settings').resolve(config)

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
