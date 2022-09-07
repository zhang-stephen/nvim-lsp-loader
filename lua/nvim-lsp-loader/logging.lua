local logging = {}

local ok, notify = pcall(require, 'notify')
local notif = ok and notify or vim.notify
local notopt = ok and {
    title = 'nvim-lsp-loader',
} or nil

---@param msg string the debug string to show
logging.debug = function(msg)
    if not require('nvim-lsp-loader.settings').current.debug then
        return
    end

    vim.schedule_wrap(notif(msg, vim.log.levels.DEBUG, notopt))
end

---@param msg string the info string to show
logging.info = function(msg)
    vim.schedule_wrap(notif(msg, vim.log.levels.INFO, notopt))
end

---@param msg string the error string to show
logging.error = function(msg)
    vim.schedule_wrap(notif(msg, vim.log.levels.ERROR, notopt))
end

return logging
