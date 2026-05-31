local MiniTest = require("mini.test")
local eq = MiniTest.expect.equality
local T = MiniTest.new_set()

T["defaults are applied"] = function()
  local cfg = require("chronicle.config")
  cfg.setup()
  eq(cfg.options.throttle_interval, 500)
  eq(cfg.options.ignore_filetypes, { "log", "gitcommit" })
  eq(cfg.options.max_entries, 0)
end

T["setup exposes snacks-source-chronicle globals"] = function()
  local cfg = require("chronicle.config")
  local rp = vim.fn.tempname()
  local wp = vim.fn.tempname()
  cfg.setup({ read_path = rp, write_path = wp })
  eq(vim.g.chronicle_read_path, vim.fs.normalize(vim.fn.expand(rp)))
  eq(vim.g.chronicle_write_path, vim.fs.normalize(vim.fn.expand(wp)))
  eq(cfg.options.read_path, vim.g.chronicle_read_path)
end

return T
