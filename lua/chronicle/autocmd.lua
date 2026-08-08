local M = {}

local AUGROUP = "chronicle"

---Install the recording autocmds. Idempotent: clears the augroup on re-setup.
function M.register()
  local options = require("chronicle.config").options
  local group = vim.api.nvim_create_augroup(AUGROUP, { clear = true })

  -- Opened files (also counts a write as a read).
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
    group = group,
    callback = function(ev)
      local bufpath = (ev.file and ev.file ~= "") and ev.file or vim.api.nvim_buf_get_name(ev.buf)
      require("chronicle.chronicle").add(options.read_path, bufpath)
    end,
  })

  -- Written files.
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    callback = function(ev)
      local bufpath = (ev.file and ev.file ~= "") and ev.file or vim.api.nvim_buf_get_name(ev.buf)
      require("chronicle.chronicle").add(options.write_path, bufpath)
    end,
  })
end

function M.unregister()
  pcall(vim.api.nvim_del_augroup_by_name, AUGROUP)
end

return M
