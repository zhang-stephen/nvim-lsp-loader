local loader = {}
local util = require('nvim-lsp-loader.util')
local installer = require('nvim-lsp-installer')
local lsp = require('lspconfig')
local root_pattern = require('lspconfig.util').root_pattern

---@param server table the user configuration of language server
---@param on_attach function the user-defined on_attach callback, wll be passed to lspconfig
---@param make_capabilities function server capabilities
---@param update_config_cb function callback after update language server configuartion
local resolve_server_conf = function(server, on_attach, make_capabilities, update_config_cb)
    local config = server.config

    config.on_attach = on_attach and on_attach
    config.capabilities = make_capabilities and make_capabilities()

    -- add root_pattern if root_dir configured
    config.root_dir = config.root_dir and root_pattern(config.root_dir)

    -- update the cmd of language server executable
    if config.cmd ~= nil and server.managed_by.lsp_installer then
        config.cmd[1] = util.resolve_lsp_execuble(config.cmd[1])
    end

    -- use this callback for user-defined operations
    if update_config_cb then
        update_config_cb(server.name, config)
    end
end

---@param lang string the name of language
---@param server table server configuration read from json
local post_load_server = function(lang, server) end

---@param name string the name of language server
local install_server = function(name)
    local available, manager = installer.get_server(name)

    if not available then
        vim.notify(string.format('unknown server for nvim-lsp-installer: %s', name), 'error')
        return false
    end

    if not manager:is_installed() then
        manager:install()
    end
end

---@param lang string the name of language
---@param server table server configuration read from json
---@param plugin_conf table configuration of plugin itself
---@return boolean
local load_server = function(lang, server, plugin_conf)
    local type_of_server_config = type(server.config)

    if server.managed_by.lsp_installer then
        install_server(server.name)
    end

    if type_of_server_config == 'table' then
        resolve_server_conf(server, plugin_conf.on_attach, plugin_conf.make_capabilities, plugin_conf.server_config_cb)
        lsp[server.name].setup(server.config)
    elseif type_of_server_config == 'string' then
        -- TODO: to support load user-defined .lua files
        vim.notify(string.format('configuration for %s in string format not supported yet!', lang), 'warning')
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
---@param plugin_conf table configurations of plugin itself
loader.load_servers = function(servers, plugin_conf)
    for lang, server in pairs(servers) do
        local loaded = load_server(lang, server, plugin_conf)

        if loaded then
            post_load_server(lang, server)
        end
    end
end

return loader
