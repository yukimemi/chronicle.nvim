local M = {}

local function open_qf(path, title)
  local lines = require("chronicle.chronicle").list(path)
  if #lines == 0 then
    require("chronicle.log").echo("chronicle history is empty", vim.log.levels.INFO)
    return
  end
  local items = {}
  for _, f in ipairs(lines) do
    items[#items + 1] = { filename = f, lnum = 1, text = f }
  end
  vim.fn.setqflist({}, " ", { title = title, items = items })
  vim.cmd("botright copen")
end

local function read_path()
  return require("chronicle.config").options.read_path
end

local function write_path()
  return require("chronicle.config").options.write_path
end

---Register the `:Chronicle*` user commands. Safe to call more than once.
function M.register()
  local function cmd(name, fn, desc)
    vim.api.nvim_create_user_command(name, fn, { desc = desc })
  end

  cmd("ChronicleReadOpen", function()
    open_qf(read_path(), "[chronicle] read")
  end, "chronicle: browse the read history (quickfix)")

  cmd("ChronicleWriteOpen", function()
    open_qf(write_path(), "[chronicle] write")
  end, "chronicle: browse the write history (quickfix)")

  cmd("ChronicleReadReset", function()
    require("chronicle.chronicle").reset(read_path())
    require("chronicle.log").echo("cleared read history")
  end, "chronicle: clear the read history")

  cmd("ChronicleWriteReset", function()
    require("chronicle.chronicle").reset(write_path())
    require("chronicle.log").echo("cleared write history")
  end, "chronicle: clear the write history")

  cmd("ChronicleEnable", function()
    require("chronicle.state").enabled = true
    require("chronicle.log").echo("recording enabled")
  end, "chronicle: resume recording")

  cmd("ChronicleDisable", function()
    require("chronicle.state").enabled = false
    require("chronicle.log").echo("recording disabled")
  end, "chronicle: pause recording")

  cmd("ChronicleToggle", function()
    local state = require("chronicle.state")
    state.enabled = not state.enabled
    require("chronicle.log").echo(state.enabled and "recording enabled" or "recording disabled")
  end, "chronicle: toggle recording")
end

return M
