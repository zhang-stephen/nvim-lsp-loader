local loader = {}
local util = require('nvim-lsp-loader.util')
local installer = require('nvim-lsp-installer')
local lsp = require('lspconfig')
local root_pattern = require('lspconfig.util').root_pattern

---@param config table the user configuration of language server
---@param on_attach function the user-defined on_attach callback, wll be passed to lspconfig
---@param make_capabilities function server capabilities
---@param update_config_cb function callback after update language server configuartion
local resolve_server_conf = function(config, on_attach, make_capabilities, update_config_cb)
    config.on_attach = on_attach and on_attach
    config.capabilities = make_capabilities and make_capabilities()

    -- add root_pattern if root_dir configured
    config.root_dir = config.root_dir and root_pattern(config.root_dir)

    -- update the cmd of language server executable
    if config.cmd ~= nil then
        config.cmd[1] = util.resolve_lsp_execuble(config.cmd[1])
    end

    -- use this callback for user-defined operations
    if update_config_cb then
        update_config_cb(config)
    end
end

---@param server table server configuration read from json
local post_load_server = function(server) end

---@param server table server configuration read from json
---@param plugin_conf table configuratio of plugin itself
---@return boolean
local load_server = function(server, plugin_conf)
    local type_of_server_config = type(server.config)

    if type_of_server_config == 'table' then
        if server.managed_by.lsp_installer then
            local available, manager = installer.get_server(server.name)

            if not available then
                vim.notify(string.format('unknown server for nvim-lsp-installer: %s', server.name), error)
                return false
            end

            if not manager:is_installed() then
                manager:install()
            end
        end

        resolve_server_conf(server.config, plugin_conf.on_attach, plugin_conf.make_capabilities, plugin_conf.config_cb)
        lsp[server.name].setup(server.config)
    elseif type_of_server_config == 'string' then
        -- TODO: to support load user-defined .lua files
        vim.notify('configuration in string format not supported yet!', 'warning')
    else
        vim.notify(
            string.format(
                'unsupport type of language server configuartion %s, expected is table or string(path)',
                type_of_server_config
            ),
            'error'
        )
        return false
    end

    return true
end

---@param servers table configurations of all servers read from json
loader.load_servers = function(servers, plugin_conf)
    local tie = util.is_array(servers) and ipairs or pairs
    for _, s in tie(servers) do
        local loaded = load_server(s, plugin_conf)

        if loaded then
            post_load_server(s)
        end
    end
end

return loader
