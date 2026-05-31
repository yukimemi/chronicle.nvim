-- Eager registration so the `:Chronicle*` commands work without calling
-- `require("chronicle").setup()` (convention over configuration). Recording (the
-- autocmds) and the snacks-source-chronicle globals only start from `setup()`.
if vim.g.loaded_chronicle then
  return
end
vim.g.loaded_chronicle = true

require("chronicle.command").register()
