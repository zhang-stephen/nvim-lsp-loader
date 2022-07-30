local loader = {}
local lspconfig_to_registry = require('nvim-lsp-loader.mappings.servers')
local log = require('nvim-lsp-loader.logging')
local settings = require('nvim-lsp-loader.settings').current

---@param server table the user configuration of language server
---@param on_attach function the user-defined on_attach callback, wll be passed to lspconfig
---@param make_capabilities function server capabilities
---@param update_config_cb function callback after update language server configuartion
local resolve_server_conf = function(server, on_attach, make_capabilities, update_config_cb)
    local config = server.config
    local util = require('nvim-lsp-loader.util')
    local root_pattern = require('lspconfig.util').root_pattern

    config.on_attach = on_attach and on_attach
    config.capabilities = make_capabilities and make_capabilities()

    -- add root_pattern if root_dir configured
    config.root_dir = config.root_dir and root_pattern(config.root_dir)

    -- update the cmd of language server executable
    if config.cmd ~= nil then
        util.resolve_executable(server.managed_by.mason, lspconfig_to_registry[server.name], config.cmd)
    end

    -- use this callback for user-defined operations
    if update_config_cb then
        update_config_cb(server.name, config)
    end
end

---@param lang string the name of language
---@param server table server configuration read from json
local post_load_server = function(lang, server) end

---@param package table the registry from mason.nvim
---@param version string | nil the version string of server
local install_server = function(package, version)
    if version ~= nil then
        log.info(string.format('%s: updating to %s', package.name, version))
    else
        log.info(string.format('%s: installing', package.name))
    end

    package:on('install:success', function(...)
        log.info(string.format('%s: installed successfully', package.name))
    end)

    package:on('install:failed', function(...)
        log.error(string.format('%s: installed failed!', package.name))
    end)

    package:install({
        version = version,
    })
end

---@param server table server configuration read from json
local check_and_install = function(server)
    if not server.managed_by.mason then
        return
    end

    local name = server.name
    local version = server.version
    local auto_update = server.auto_update
    local p = require('mason-registry').get_package(lspconfig_to_registry[name])

    if not p then
        error(string.format('cannot find server %s', name))
        return
    end

    if p:is_installed() then
        -- TODO: update/change version should be done with async?
        if version ~= nil then
            p:get_installed_version(function(ok, installed_version)
                if ok and version ~= installed_version then
                    install_server(p, version)
                end
            end)
        elseif auto_update or (auto_update == nil and settings.auto_update) then
            p:check_new_version(function(ok, ver)
                if ok then
                    install_server(p, ver.latest_version)
                end
            end)
        end
    else
        install_server(p, version)
    end
end

---@param lang string the name of language
---@param server table server configuration read from json
---@return boolean
local load_server = function(lang, server)
    local type_of_server_config = type(server.config)
    local lsp = require('lspconfig')

    check_and_install(server)

    if type_of_server_config == 'table' then
        resolve_server_conf(server, settings.on_attach, settings.make_capabilities, settings.server_config_cb)
        lsp[server.name].setup(server.config)
    elseif type_of_server_config == 'string' then
        -- TODO: to support load user-defined .lua files
        log.error(string.format('configuration for %s in string format not supported yet!', lang))
    else
        log.error(
            string.format(
                'unsupport type of language server configuartion %s, expected is table or string(path)',
                type_of_server_config
            )
        )
        return false
    end

    return true
end

---@param servers table configurations of all servers read from json
loader.load_servers = function(servers)
    for lang, server in pairs(servers) do
        local loaded = load_server(lang, server)

        if loaded then
            post_load_server(lang, server)
        end
    end
end

return loader
