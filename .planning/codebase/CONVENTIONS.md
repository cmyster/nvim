# Coding Conventions

**Analysis Date:** 2026-03-09

## Naming Patterns

**Files:**
- Plugin files: lowercase singular noun describing the concern (`colorscheme.lua`, `formatting.lua`, `terminal.lua`)
- Config files: lowercase plural noun (`keymaps.lua`, `autocmds.lua`, `options.lua`)
- Exception: `helpscreen.lua` uses compound word (no separator)
- Use `.lua` extension exclusively; no `.vim` files

**Functions:**
- Use `snake_case` for all Lua functions: `build_lines()`, `diff_source()`, `close_help()`
- Prefix local helper functions with `local function`: never expose unless returning a module
- Module public functions use `M.method_name()` pattern (see `lua/config/helpscreen.lua`)

**Variables:**
- `snake_case` for local variables: `help_buf`, `help_win`, `auto_close_timer`
- Short aliases at file top for frequently used APIs:
  - `local opt = vim.opt` in `lua/config/options.lua`
  - `local map = vim.keymap.set` in `lua/config/keymaps.lua`
  - `local lint = require("lint")` in `lua/plugins/linting.lua`

**Augroups:**
- Use `kebab-case` prefixed with `project-` for custom augroups: `"project-lint"`, `"project-lsp-attach"`, `"project-diag-float"`
- Built-in behavior augroups use `snake_case`: `"highlight_yank"`, `"restore_cursor"`, `"strip_whitespace"`

## Code Style

**Formatting:**
- Formatter: `stylua` (configured in `lua/plugins/formatting.lua`, installed via Mason in `lua/plugins/linting.lua`)
- No `.stylua.toml` config file detected -- uses stylua defaults
- Global default indentation: 2 spaces (set in `lua/config/options.lua`)
- Line length guide: 120 columns (`opt.colorcolumn = "120"` in `lua/config/options.lua`)
- Per-language overrides: Python and Rust use 4 spaces (autocmd in `lua/config/autocmds.lua`)

**Linting:**
- Linter: `luacheck` (installed via Mason, configured in `lua/plugins/linting.lua`)
- Config: `.luacheckrc` at project root
- Key settings: `vim` declared as global, `std = "luajit"`, `max_line_length = false`

## Plugin Spec Style

**Prefer `opts` over `config` function:**
- Use `opts = { ... }` (plain table) whenever the plugin's setup accepts a table directly
- Use `config = function(_, opts)` ONLY when imperative code is required (e.g., `lua/plugins/lsp.lua` needs `vim.lsp.config()` calls before `setup()`, `lua/plugins/linting.lua` needs autocmd creation)
- Document the exception with a comment explaining why `config` is needed

**Lazy-loading patterns:**
- `event = { "BufReadPost" }` for buffer-aware plugins (gitsigns, nvim-lint)
- `event = { "BufWritePre" }` for save-triggered plugins (conform.nvim)
- `event = "VeryLazy"` for UI enhancements (which-key)
- `event = "InsertEnter"` for insert-mode plugins (autopairs)
- `event = "LspAttach"` for LSP-dependent plugins (fidget.nvim)
- `keys = { ... }` for on-demand plugins (neo-tree, toggleterm, trouble)
- `cmd = { ... }` for command-triggered plugins (trouble, conform)
- `ft = "lua"` for filetype-specific plugins (lazydev)
- `lazy = false` for critical always-loaded plugins (colorscheme, treesitter, vim-fugitive)

**Dependency declarations:**
- Declare dependencies even if already in `lua/plugins/deps.lua` for load-order guarantees
- Use inline `{ "pkg", opts = {} }` for dependencies that just need `setup()` called

**Version pinning:**
- Use `branch = "v3.x"` or `branch = "master"` for branch-pinned plugins
- Use `tag = "v1.6.1"` for exact version pins (fidget.nvim)
- Use `version = "1.*"` for semver-compatible releases (blink.cmp)
- Use `version = "*"` for latest stable (toggleterm)

## Return Style

**Plugin files:** Always `return { ... }` with one or more plugin spec tables. Multiple specs in one file are allowed when logically grouped (e.g., `lua/plugins/git.lua` returns gitsigns + fugitive).

**Config modules:** Files in `lua/config/` either:
- Execute side effects directly on `require()` (`options.lua`, `keymaps.lua`, `autocmds.lua`)
- Return a module table with `.setup()` (`helpscreen.lua`)

## Import Organization

**Order in `init.lua`:**
1. Leader key assignment (must be first)
2. Config module requires: `config.options`, `config.keymaps`, `config.autocmds`, `config.helpscreen`
3. lazy.nvim bootstrap
4. `require("lazy").setup()` with `{ import = "plugins" }`

**Within plugin files:**
- Top-level `vim.diagnostic.config()` and autocmd setup run before the `return` statement when needed (`lua/plugins/lsp.lua`)
- Local helper functions defined before the return block (`lua/plugins/statusline.lua`: `diff_source()`)

**Path Aliases:**
- None. All requires use standard Lua module paths: `require("config.options")`, `require("plugins")`

## Keymap Conventions

**Pattern:** Use `vim.keymap.set(mode, lhs, rhs, opts)` with a `desc` field always present.

**Desc format:**
- Global keymaps: short imperative phrase (`"Move to left split"`, `"Delete buffer"`)
- LSP keymaps: prefixed with `"LSP: "` and use bracket mnemonics (`"LSP: [G]oto [D]efinition"`)
- Plugin keymaps in `keys = { ... }`: short phrase (`"Toggle file tree"`, `"Format buffer"`)

**Leader groups:**
- `<leader>b` - Buffer operations
- `<leader>e` - Explorer/file tree
- `<leader>f` - Format
- `<leader>g` - Git
- `<leader>h` - Help
- `<leader>t` - Terminal
- `<leader>x` - Diagnostics

**Buffer-scoped keymaps:** Always pass `{ buffer = bufnr }` or `{ buffer = event.buf }` for LSP and plugin on_attach keymaps.

## Autocmd Conventions

**Pattern:**
```lua
vim.api.nvim_create_autocmd("EventName", {
  group = vim.api.nvim_create_augroup("group-name", { clear = true }),
  desc = "Human-readable description",
  callback = function()
    -- implementation
  end,
})
```

**Rules:**
- Always use a named augroup with `clear = true` to prevent duplicate autocmds on config reload
- Always include a `desc` field
- Use `callback` (function), not `command` (string), for Lua implementations
- Number autocmds with comments in files that contain multiple (`lua/config/autocmds.lua`)

## Comment Style

**When to Comment:**
- Every plugin file starts with a header comment: filename, purpose, and critical notes
- API version warnings are marked with uppercase labels: `CRITICAL:`, `NOTE:`, `REQUIRED:`
- Inline comments explain "why" not "what" -- especially for non-obvious config values
- Reference codes used for traceability: `LSP-03`, `SL-02`, `GIT-01`, `CMP-04`
- Source URLs included for external references: `-- Source: https://...`

**Comment density:** High. Nearly every significant config line has an explanatory comment. Maintain this convention for new code.

**JSDoc/TSDoc:** Not applicable (Lua codebase). Use `---@module` and `---@type` annotations for type hints where supported (see `lua/plugins/qol.lua` indent-blankline spec).

## Error Handling

**Patterns:**
- Use `pcall()` for operations that may fail: `pcall(vim.api.nvim_win_set_cursor, 0, mark)` in `lua/config/autocmds.lua`
- Check validity before operating on windows/buffers: `vim.api.nvim_win_is_valid(help_win)` in `lua/config/helpscreen.lua`
- Bootstrap errors: display via `vim.api.nvim_echo()` with ErrorMsg/WarningMsg highlight groups, then `os.exit(1)` (see `init.lua`)
- Timer cleanup: always `stop()` then `close()` uv timers before nilling (`lua/config/helpscreen.lua`)

## Module Design

**Exports:**
- Plugin files export a table of lazy.nvim spec(s) via `return { ... }`
- Config modules that need a setup phase export `M = {}` with `M.setup()` and `return M`
- Config modules with only side effects have no explicit exports

**Barrel Files:**
- No barrel files. lazy.nvim's `{ import = "plugins" }` auto-discovers all files in `lua/plugins/`

---

*Convention analysis: 2026-03-09*
