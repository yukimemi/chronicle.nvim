local M = {}

---Configure chronicle and start recording read/write history.
---@param opts? chronicle.Options
function M.setup(opts)
  local cfg = require("chronicle.config")
  cfg.setup(opts)
  require("chronicle.state").enabled = cfg.options.enabled
  require("chronicle.command").register()
  require("chronicle.autocmd").register()
end

-- Convenience Lua API.

---The read history (opened files), most-recent-first.
---@return string[]
function M.read()
  return require("chronicle.chronicle").list(require("chronicle.config").options.read_path)
end

---The write history (written files), most-recent-first.
---@return string[]
function M.write()
  return require("chronicle.chronicle").list(require("chronicle.config").options.write_path)
end

function M.enable()
  require("chronicle.state").enabled = true
end

function M.disable()
  require("chronicle.state").enabled = false
end

return M
