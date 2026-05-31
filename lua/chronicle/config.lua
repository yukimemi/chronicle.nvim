local M = {}

---@class chronicle.Options
---@field notify boolean             Emit `vim.notify` on record (gated by `log_level`). Default false.
---@field log_level "trace"|"debug"|"info"|"warn"|"error"
---@field enabled boolean            Whether recording starts on. Default true.
---@field ignore_filetypes string[]  Filetypes never recorded.
---@field read_path string           History file of opened files (most-recent-first).
---@field write_path string          History file of written files (most-recent-first).
---@field throttle_interval integer  Min ms between recording the same file to the same history. Default 500.
---@field max_entries integer        Cap each history to N newest entries. 0 = unlimited.

M.defaults = {
  notify = false,
  log_level = "warn",
  enabled = true,
  ignore_filetypes = { "log", "gitcommit" },
  read_path = vim.fn.stdpath("state") .. "/chronicle/read",
  write_path = vim.fn.stdpath("state") .. "/chronicle/write",
  throttle_interval = 500,
  max_entries = 0,
}

M.options = vim.deepcopy(M.defaults)

---@param opts? chronicle.Options
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
  M.options.read_path = vim.fs.normalize(vim.fn.expand(M.options.read_path))
  M.options.write_path = vim.fs.normalize(vim.fn.expand(M.options.write_path))

  -- Expose the resolved paths as globals so snacks-source-chronicle (which reads
  -- `vim.g.chronicle_read_path` / `vim.g.chronicle_write_path` directly) keeps
  -- working unchanged.
  vim.g.chronicle_read_path = M.options.read_path
  vim.g.chronicle_write_path = M.options.write_path
end

return M
