local M = {}

local AUGROUP = "chronicle"

---Install the recording autocmds. Idempotent: clears the augroup on re-setup.
function M.register()
  local options = require("chronicle.config").options
  local group = vim.api.nvim_create_augroup(AUGROUP, { clear = true })

  -- Opened files (also counts a write as a read).
  vim.api.nvim_create_autocmd({ "BufRead", "BufWritePost" }, {
    group = group,
    callback = function()
      require("chronicle.chronicle").add(options.read_path, vim.api.nvim_buf_get_name(0))
    end,
  })

  -- Written files.
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    callback = function()
      require("chronicle.chronicle").add(options.write_path, vim.api.nvim_buf_get_name(0))
    end,
  })
end

function M.unregister()
  pcall(vim.api.nvim_del_augroup_by_name, AUGROUP)
end

return M
