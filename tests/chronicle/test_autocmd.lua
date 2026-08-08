local MiniTest = require("mini.test")
local eq = MiniTest.expect.equality

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      require("chronicle.state").enabled = true
      vim.cmd("enew!")
      vim.bo.filetype = ""
    end,
  },
})

local function norm(p)
  return vim.fs.normalize(vim.fn.fnamemodify(p, ":p"))
end

local function real_file(name)
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, "p")
  local p = dir .. "/" .. name
  local fd = assert(io.open(p, "w"))
  fd:write("hello")
  fd:close()
  return p
end

T["autocmd uses ev parameters correctly on BufReadPost and BufWritePost even if current buffer changes"] = function()
  local read_p = vim.fn.tempname()
  local write_p = vim.fn.tempname()
  require("chronicle").setup({
    read_path = read_p,
    write_path = write_p,
    throttle_interval = 0,
  })

  local f = real_file("ev_target.txt")
  local dummy = real_file("dummy.txt")
  local dummy_buf = vim.fn.bufadd(dummy)

  -- Register a preceding autocmd that switches active buffer during BufReadPost
  local group = vim.api.nvim_create_augroup("test_switch_buf", { clear = true })
  vim.api.nvim_create_autocmd("BufReadPost", {
    group = group,
    callback = function()
      vim.api.nvim_set_current_buf(dummy_buf)
    end,
  })

  vim.cmd("edit " .. vim.fn.fnameescape(f))

  local C = require("chronicle.chronicle")
  -- Chronicle should record `f` (the target of BufReadPost), not `dummy` (the active buffer after switch)
  eq(C.list(read_p), { norm(f) })
end

return T
