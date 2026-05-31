local M = {}

local uv = vim.uv

-- key (chrono_path .. "\0" .. bufpath) -> last recorded ms (vim.uv.now())
local throttle = {}

local function cfg()
  return require("chronicle.config").options
end

local function read_lines(path)
  if vim.fn.filereadable(path) == 0 then
    return {}
  end
  return vim.fn.readfile(path)
end

local function write_lines(path, lines)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  vim.fn.writefile(lines, path)
end

---Record `bufpath` at the top of the history file `chrono_path` (most-recent-
---first, de-duplicated). No-op when disabled, for ignored filetypes, for
---non-file buffers, or within the throttle window.
---@param chrono_path string
---@param bufpath string
function M.add(chrono_path, bufpath)
  if not require("chronicle.state").enabled then
    return
  end
  local options = cfg()
  if vim.tbl_contains(options.ignore_filetypes or {}, vim.bo.filetype) then
    return
  end
  if not bufpath or bufpath == "" then
    return
  end
  bufpath = vim.fs.normalize(vim.fn.fnamemodify(bufpath, ":p"))
  if vim.fn.filereadable(bufpath) == 0 then
    return -- only track files that exist on disk
  end

  local key = chrono_path .. "\0" .. bufpath
  local now = uv.now()
  local last = throttle[key]
  if last and (now - last) < (options.throttle_interval or 0) then
    return
  end
  throttle[key] = now

  -- read-modify-write: move bufpath to the top, drop any earlier occurrence.
  local out = { bufpath }
  for _, line in ipairs(read_lines(chrono_path)) do
    if line ~= "" and line ~= bufpath then
      out[#out + 1] = line
    end
  end
  local maxn = options.max_entries or 0
  if maxn > 0 and #out > maxn then
    for i = #out, maxn + 1, -1 do
      out[i] = nil
    end
  end
  write_lines(chrono_path, out)
  require("chronicle.log").info("chronicle + " .. bufpath)
end

---The history at `path`, most-recent-first.
---@param path string
---@return string[]
function M.list(path)
  return read_lines(path)
end

---Delete the history file at `path`.
---@param path string
function M.reset(path)
  if vim.fn.filereadable(path) == 1 then
    vim.fn.delete(path)
  end
end

return M
