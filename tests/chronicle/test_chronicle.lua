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

-- Create a real file on disk in a fresh temp dir; return its path.
local function real_file(name)
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, "p")
  local p = dir .. "/" .. name
  local fd = assert(io.open(p, "w"))
  fd:write("x")
  fd:close()
  return p
end

local function fresh(opts)
  opts = opts or {}
  opts.read_path = opts.read_path or vim.fn.tempname()
  opts.throttle_interval = opts.throttle_interval or 0
  require("chronicle.config").setup(opts)
  return opts.read_path, require("chronicle.chronicle")
end

T["add records a path at the top, de-duplicated"] = function()
  local chrono, C = fresh()
  local f1, f2 = real_file("a.txt"), real_file("b.txt")

  C.add(chrono, f1)
  C.add(chrono, f2)
  C.add(chrono, f1) -- re-adding f1 moves it back to the top

  local lines = C.list(chrono)
  eq(#lines, 2) -- de-duplicated, not 3
  eq(lines[1], norm(f1))
  eq(lines[2], norm(f2))
end

T["throttle skips re-recording within the interval"] = function()
  local chrono, C = fresh({ throttle_interval = 100000 })
  local f, g = real_file("x.txt"), real_file("y.txt")

  C.add(chrono, f)
  C.add(chrono, g)
  C.add(chrono, f) -- throttled: not moved back to the top

  eq(C.list(chrono)[1], norm(g))
end

T["ignored filetypes are not recorded"] = function()
  local chrono, C = fresh({ ignore_filetypes = { "log" } })
  vim.bo.filetype = "log"
  C.add(chrono, real_file("x.txt"))
  eq(C.list(chrono), {})
end

T["non-existent paths are skipped"] = function()
  local chrono, C = fresh()
  C.add(chrono, vim.fn.tempname() .. "/nope.txt")
  eq(C.list(chrono), {})
end

T["disabled state suppresses recording"] = function()
  local chrono, C = fresh()
  require("chronicle.state").enabled = false
  C.add(chrono, real_file("x.txt"))
  eq(C.list(chrono), {})
end

T["max_entries trims to the newest N"] = function()
  local chrono, C = fresh({ max_entries = 2 })
  C.add(chrono, real_file("a.txt"))
  C.add(chrono, real_file("b.txt"))
  local c = real_file("c.txt")
  C.add(chrono, c)

  local lines = C.list(chrono)
  eq(#lines, 2)
  eq(lines[1], norm(c)) -- newest kept
end

T["reset clears the history"] = function()
  local chrono, C = fresh()
  C.add(chrono, real_file("a.txt"))
  eq(#C.list(chrono), 1)
  C.reset(chrono)
  eq(C.list(chrono), {})
end

return T
