<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/yukimemi/chronicle.nvim/main/assets/logo-dark.svg">
  <img src="https://raw.githubusercontent.com/yukimemi/chronicle.nvim/main/assets/logo.svg" alt="chronicle — read & write file history" width="520">
</picture>

<p><em>read &amp; write file history.</em></p>

[![CI](https://github.com/yukimemi/chronicle.nvim/actions/workflows/ci.yml/badge.svg)](https://github.com/yukimemi/chronicle.nvim/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/yukimemi/chronicle.nvim/blob/main/LICENSE)
[![Neovim 0.10+](https://img.shields.io/badge/Neovim-0.10+-57A143?logo=neovim&logoColor=white)](https://neovim.io)

</div>

Record the files you open and the files you write to two most-recent-first
history files, so you can jump back to where you were. A pure-Lua, Neovim-only
rewrite of [chronicle.vim](https://github.com/yukimemi/chronicle.vim) (no Deno /
denops dependency).

Pairs with
[snacks-source-chronicle](https://github.com/yukimemi/snacks-source-chronicle)
for a picker over the history — chronicle.nvim keeps the same file format and
`vim.g.chronicle_read_path` / `vim.g.chronicle_write_path` globals, so that
source works unchanged.

## Requirements

- Neovim >= 0.10

## Install

With [rvpm](https://github.com/yukimemi/rvpm) (recommended):

```sh
rvpm add yukimemi/chronicle.nvim --on-event BufReadPre,BufNewFile --on-cmd '/^Chronicle.*$/'
```

Or in `config.toml`:

```toml
[[plugins]]
url = "https://github.com/yukimemi/chronicle.nvim"
on_event = ["BufReadPre", "BufNewFile"]
on_cmd = ["/^Chronicle.*$/"]
opts = {}
```

> Here `setup()` is **required**: the commands come up either way, but nothing
> is switched automatically until `require("chronicle").setup(...)` installs the
> autocmds. **rvpm >= 3.45.0 handles it for you** — put `opts = {}` (or your
> options) in the `[[plugins]]` entry and rvpm calls
> `require("chronicle").setup(<opts>)` right before the plugin's `after.lua`
> (same convention as lazy.nvim's `opts`). Use a hook
> (`rvpm edit yukimemi/chronicle.nvim --after`) only when the options need a Lua
> function, which TOML cannot express.

Or with [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "yukimemi/chronicle.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {},
}
```

`opts` is passed straight to `require("chronicle").setup()`.

## Configuration

Defaults:

```lua
require("chronicle").setup({
  notify = false,
  log_level = "warn",
  enabled = true,
  ignore_filetypes = { "log", "gitcommit" },
  read_path = vim.fn.stdpath("state") .. "/chronicle/read",
  write_path = vim.fn.stdpath("state") .. "/chronicle/write",
  throttle_interval = 500, -- ms between recording the same file to the same history
  max_entries = 0,         -- cap each history to N newest entries (0 = unlimited)
})
```

`BufRead` / `BufWritePost` append to the read history; `BufWritePost` also
appends to the write history. Each history is most-recent-first and
de-duplicated.

## Commands

| Command | Action |
| --- | --- |
| `:ChronicleReadOpen` / `:ChronicleWriteOpen` | Browse the read / write history (quickfix) |
| `:ChronicleReadReset` / `:ChronicleWriteReset` | Clear the read / write history |
| `:ChronicleEnable` / `:ChronicleDisable` / `:ChronicleToggle` | Control recording |

## Lua API

```lua
local chronicle = require("chronicle")
chronicle.read()   -- string[] of opened files, most-recent-first
chronicle.write()  -- string[] of written files, most-recent-first
chronicle.enable()
chronicle.disable()
```

## Health

```vim
:checkhealth chronicle
```

## License

MIT
