# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## コンセプト

- **denops 廃止・pure Lua / Neovim 専用**: [`chronicle.vim`](https://github.com/yukimemi/chronicle.vim) (denops/Deno) の後継。開いたファイル (read) と書いたファイル (write) を、最新先頭・重複排除のテキスト履歴ファイル2本に記録する。
- **snacks-source-chronicle 互換が最重要**: [snacks-source-chronicle](https://github.com/yukimemi/snacks-source-chronicle) は履歴ファイルを `vim.fn.readfile(vim.g.chronicle_read_path)` で**直接読む** (denops dispatcher 非依存)。よって chronicle.nvim は **同じファイル形式 (最新先頭・1行1パス) + `vim.g.chronicle_read_path` / `vim.g.chronicle_write_path` グローバル** を維持すれば snacks 側は無改修で動く。`config.setup()` がこのグローバルを必ずセットする。
- **設定はテーブル一本**: `g:chronicle_*` の設定系グローバルは廃止し `setup()` テーブルへ。ただし `vim.g.chronicle_read_path`/`write_path` は snacks-source との**契約**なので setup で再公開する。
- **Convention over Configuration**: `plugin/chronicle.lua` が `:Chronicle*` を eager 登録。記録 (autocmd) + snacks 用グローバルは `setup()` 起点。
- **Notify ゲート契約**: background は `log.at` 系、ユーザ起点コマンドは `log.echo`。

## Git ワークフロー

- **main 直 push しない。** フィーチャーブランチ + PR。**PR / commit は英語** (Conventional Commits)。
- 全 PR で Gemini / CodeRabbit レビュー。指摘対処 (fix push → @-mention reply)、actionable 消失 + オーナー (@yukimemi) 承認まで merge しない。bot-authored PR は除外。

## Development Commands

テストは **mini.test** (plenary は 2026-06-30 アーカイブ)。`scripts/run_tests.lua` (headless, cquit)。

```bash
git clone --depth 1 https://github.com/echasnovski/mini.nvim deps/mini.nvim
# または既存 clone を $MINI_NVIM で再利用

set -e
status=0
for f in tests/chronicle/test_*.lua; do
  nvim -u NONE -l scripts/run_tests.lua "$f" || status=$?
done
exit $status
```

- `nvim -u NONE -l` で user config を読まずに実行。spec 名は **`test_*.lua`**。

## アーキテクチャ

### ファイル構成

```text
plugin/chronicle.lua        — :Chronicle* を eager 登録
lua/chronicle/
  init.lua                  — setup() + Lua API (read/write/enable/disable)
  config.lua                — defaults + setup。read_path/write_path を expand し vim.g に再公開 (snacks 契約)
  log.lua                   — notify ゲート + echo
  state.lua                 — enabled フラグ (memory)
  chronicle.lua             — コア add() (throttle + dedup + 最新先頭 RMW)、list()、reset()
  autocmd.lua               — BufRead/BufWritePost → read 履歴、BufWritePost → write 履歴
  command.lua               — :Chronicle{ReadOpen,WriteOpen,ReadReset,WriteReset,Enable,Disable,Toggle}
  health.lua                — :checkhealth chronicle (snacks グローバル一致も検査)
scripts/run_tests.lua
tests/chronicle/test_*.lua
.github/workflows/ci.yml    — test (ubuntu/macos/windows × stable/nightly) + stylua lint
```

### 記録のコア (`chronicle.lua`)

- `add(chrono_path, bufpath)`: enabled / ignore_filetypes (`vim.bo.filetype`) / 空 buf / `filereadable` (実在ファイルのみ) を弾く。throttle key = `chrono_path .. "\0" .. bufpath`、`vim.uv.now()` で `throttle_interval` ms 以内なら skip。
- **同期 read-modify-write**: `readfile` で現在の履歴を読み、bufpath を先頭に置き重複を除去、`max_entries>0` なら末尾を切り詰め、`writefile`。履歴は最新先頭。throttle 付き・小ファイルなので体感ブロックなし (BufRead 自体が元々重い)。単一スレッドで RMW が原子的なのでレースなし。
- `list(path)` = `readfile`、`reset(path)` = `delete`。

### snacks 互換 (`config.lua`)

`setup()` で `read_path`/`write_path` を `expand` + `vim.fs.normalize` し、`vim.g.chronicle_read_path` / `vim.g.chronicle_write_path` にセット。snacks-source-chronicle はこのグローバルを読んで `readfile` するので、**ここを壊すと picker が動かなくなる**。`health.lua` で一致を検査する。

## 設計原則

- **記録は軽量・同期.** throttle + 小ファイルの RMW。失敗しても Neovim を止めない。
- **Notify ゲート契約.** background `log.at` / ユーザ起点 `log.echo`。
- **テスト先行.** add の挙動 (最新先頭・dedup・throttle・ignore ft・実在ファイルのみ・max_entries・reset) と snacks グローバルの公開を `tests/chronicle/test_*.lua` で守る。
- **Windows 特性.** CI に `windows-latest`。`nvim_buf_get_name` / `fnamemodify(":p")` 正規化、パス区切りに注意。テストは `nvim -u NONE -l` で全 OS 共通。

## 移植元との差分 (denops 版からの設計変更)

- `g:chronicle_*` 設定グローバル → `setup()` テーブル (`vim.g.chronicle_read_path`/`write_path` のみ snacks 契約で維持)。`debug` → `log_level` + notify ゲート。
- denops dispatcher `listRead`/`listWrite` → Lua API `read()`/`write()`。`open` → `:ChronicleReadOpen`/`:ChronicleWriteOpen`。
- `max_entries` を新設 (履歴ファイルの肥大を任意で抑制)。
- 既定パスを `~/.cache/chronicle` → `stdpath("state")/chronicle` に変更 (ユーザは hook で従来パスを指定可)。
