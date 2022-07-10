local util = {}

---@param path string
---@return boolean
local is_absolute_path = function(path)
    local os_name = vim.loop.os_uname().sysname

    if os_name == 'Windows_NT' then
        return path[2] == ':'
    else
        return path[1] == '/'
    end
end

---@param patterns table<string> | nil
---@return string path
util.resolve_work_path = function(patterns)
    local cwd = vim.fn.getcwd()
    local root = require('lspconfig.util').root_pattern(patterns)(cwd)
    return (root == nil or #root == 0) and cwd or root
end

---@return string
util.get_lsp_installed_path = function()
    return require('nvim-lsp-installer.settings').current.install_root_dir
end

---@param path string the relative path relative to lsp server installation path
---@return string path the absolute path of lsp execuble file
util.resolve_lsp_execuble = function(path)
    local lsp_installed_path = util.get_lsp_installed_path()
    return is_absolute_path(path) and path or lsp_installed_path .. '/' .. path
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

    if util.has_nvim() then
        return vim.tbl_islist(t)
    end

    local i = 1

    for _ in pairs(t) do
        if t[i] == nil then
            return false
        end
        i = i + 1
    end
    
    return true
end

return util
