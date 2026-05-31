local M = {}

local h = vim.health
local start = h.start or h.report_start
local ok = h.ok or h.report_ok
local info = h.info or h.report_info
local warn = h.warn or h.report_warn

local function count(path)
  if vim.fn.filereadable(path) == 0 then
    return 0
  end
  return #vim.fn.readfile(path)
end

function M.check()
  start("chronicle")

  if vim.fn.has("nvim-0.10") == 1 then
    ok("Neovim >= 0.10")
  else
    warn("Neovim 0.10+ recommended (vim.uv)")
  end

  local options = require("chronicle.config").options
  local state = require("chronicle.state")

  info("enabled: " .. tostring(state.enabled))
  info(("read history:  %s (%d entries)"):format(options.read_path, count(options.read_path)))
  info(("write history: %s (%d entries)"):format(options.write_path, count(options.write_path)))
  info(
    ("throttle: %dms, max_entries: %s"):format(
      options.throttle_interval or 0,
      (options.max_entries or 0) > 0 and tostring(options.max_entries) or "unlimited"
    )
  )

  if vim.g.chronicle_read_path == options.read_path then
    ok("vim.g.chronicle_read_path set (snacks-source-chronicle compatible)")
  else
    warn("vim.g.chronicle_read_path not set — call require('chronicle').setup()")
  end
end

return M
