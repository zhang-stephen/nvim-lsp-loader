local util = {}

---@param patterns table<string> | nil
---@return string path
util.resolve_work_path = function(patterns)
    local cwd = vim.fn.getcwd()
    local root = require('lspconfig.util').root_pattern(patterns)(cwd)
    return (root == nil or #root == 0) and cwd or root
end

---@param managed boolean if this server is managed by mason.nvim
---@param registry string the canocial name of mason.nvim
---@param options table<string> the command and options for server
util.resolve_executable = function(managed, registry, options)
    if not managed then
        return options
    end

    -- HACK: this is not open API from mason.nvim, risk!
    local mr = string.format('mason-registry.%s', registry)
    local executable = vim.tbl_keys(require(mr):get_receipt()._value.links.bin)[1]
    local mason_bin_path = require('mason.settings').current.install_root_dir .. '/bin'
    options[1] = string.format('%s/%s', mason_bin_path, executable)
end

---@param path string
---@return boolean
util.filereadable = function(path)
    return vim.fn.filereadable(path) == 1
end

---@return boolean
util.has_nvim = function()
    local ok, _ = pcall(vim.fn.has, 'nvim')
    return ok
end

---@param t table
---@return boolean
util.is_array = function(t)
    if type(t) ~= 'table' then
        return false
    end

    return vim.tbl_islist(t)
end

return util
