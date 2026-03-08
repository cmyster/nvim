# Coding Conventions

**Analysis Date:** 2026-03-08

## Naming Patterns

**Files:**
- All lowercase, single-word names: `colorscheme.lua`, `formatting.lua`, `linting.lua`
- Config modules match their concern: `options.lua`, `keymaps.lua`, `autocmds.lua`
- Plugin files named by feature domain (not plugin name): `filetree.lua` (not `neo-tree.lua`), `terminal.lua` (not `toggleterm.lua`)
- Exception: `qol.lua` bundles multiple small quality-of-life plugins into one file

**Functions:**
- Use `snake_case` for all Lua functions: `build_lines()`, `diff_source()`, `close_help()`
- Module-exported functions use `M.method_name()` pattern: `M.open()`, `M.setup()`
- Inline callbacks are anonymous: `function() ... end` or `function(event) ... end`
- Local helper functions defined before use (top of file)

**Variables:**
- `snake_case` for all locals: `help_buf`, `help_win`, `auto_close_timer`, `lazypath`
- Short aliases for frequently used APIs at top of file:
  - `local opt = vim.opt` in `lua/config/options.lua`
  - `local map = vim.keymap.set` in `lua/config/keymaps.lua`
  - `local lint = require("lint")` in `lua/plugins/linting.lua`
- Module-scoped state uses file-level locals (not globals): see `help_buf`, `help_win`, `auto_close_timer` in `lua/config/helpscreen.lua`

**Augroups:**
- Use `project-` prefix for custom autocommand groups: `project-lsp-attach`, `project-lint`, `project-diag-float`
- Exception: config-level augroups use descriptive names without prefix: `highlight_yank`, `restore_cursor`, `strip_whitespace`, `json_conceal`, `filetype_indent`

## Code Style

**Formatting:**
- Tool: `stylua` (configured via mason-tool-installer in `lua/plugins/linting.lua`)
- Default indentation: 2 spaces (set in `lua/config/options.lua`: `shiftwidth = 2`, `tabstop = 2`)
- Exception: `lua/config/helpscreen.lua` and `lua/plugins/lsp.lua` use tabs (inconsistency -- see CONCERNS.md)
- Line length guide: column 80 (`colorcolumn = "80"` in `lua/config/options.lua`)
- No trailing whitespace (auto-stripped on save via `BufWritePre` autocmd in `lua/config/autocmds.lua`)

**Linting:**
- Tool: `luacheck` for Lua files (configured in `.luacheckrc`)
- `.luacheckrc` declares `vim` as a global, uses `luajit` std library, disables max line length
- Location: `.luacheckrc` at project root

## Plugin Spec Style

**Prefer `opts` table over `config` function:**
- Use `opts = { ... }` when plugin setup is a plain table (most plugins)
- Use `config = function(_, opts)` ONLY when imperative code is required (e.g., `lua/plugins/linting.lua` for autocmd creation, `lua/plugins/lsp.lua` for `vim.lsp.config()` calls)
- Document the reason when using `config` instead of `opts`: see comment in `lua/plugins/linting.lua` lines 55-58

**Lazy-loading conventions:**
- `event = { ... }` for plugins triggered by buffer events: `"BufReadPost"`, `"BufWritePost"`, `"BufNewFile"`, `"BufWritePre"`
- `keys = { ... }` for plugins triggered by keymaps: provide `desc` for every key entry
- `cmd = { ... }` for plugins triggered by commands: `"Trouble"`, `"ConformInfo"`
- `ft = "lua"` for filetype-specific plugins: `lazydev.nvim`
- `lazy = false` only when a plugin MUST load at startup (colorscheme, treesitter, fugitive) -- always add a comment explaining why
- `lazy = true` for pure library dependencies: `plenary.nvim`, `nui.nvim`, `nvim-web-devicons`

**Return style:**
- Every plugin file returns a single table: `return { ... }`
- Multiple plugin specs are returned as multiple entries in the table: see `lua/plugins/linting.lua`, `lua/plugins/git.lua`, `lua/plugins/statusline.lua`, `lua/plugins/qol.lua`
- Single-plugin files still wrap in outer table: `return { { "plugin/name", ... } }`

## Import Organization

**Order (in `init.lua`):**
1. Leader key assignment (must be first)
2. `require("config.options")` -- vim options
3. `require("config.keymaps")` -- global keymaps
4. `require("config.autocmds")` -- autocommands
5. `require("config.helpscreen").setup()` -- module with setup method
6. lazy.nvim bootstrap and `require("lazy").setup()`

**Plugin auto-discovery:**
- lazy.nvim `{ import = "plugins" }` auto-discovers all files in `lua/plugins/`
- No manual require of individual plugin files
- Load order controlled via `dependencies` in each plugin spec, not file naming

**Path Aliases:**
- None used. All requires use relative dot-notation: `require("config.options")`, `require("plugins.lsp")`

## Comment Style

**File-level header comments:**
- Every plugin file starts with a comment describing its purpose: `-- lua/plugins/formatting.lua` followed by a brief description
- Include critical warnings at top when version/branch matters: see `lua/plugins/treesitter.lua` lines 1-5

**Inline reference tags:**
- Some files use tag-style references: `GIT-01`, `GIT-02`, `SL-01` through `SL-04`, `LSP-02` through `LSP-05`, `CMP-04`, `QOL-04`
- Tags are used in comments to cross-reference related decisions within and across files
- Format: `CATEGORY-NN` (uppercase category, hyphen, two-digit number)

**Decision documentation:**
- Explain WHY a setting is chosen, not just WHAT it does
- Document version-specific pitfalls: "DO NOT change branches without understanding the API differences" (`lua/plugins/treesitter.lua`)
- Document removed/renamed APIs: "TroubleToggle is REMOVED in v3" (`lua/plugins/diagnostics.lua`)
- Document when NOT to do something: "do NOT call navic.attach() in lsp.lua" (`lua/plugins/statusline.lua`)

**Comment density:**
- High. Nearly every non-trivial option has an inline comment explaining its purpose
- Comments explain the "why" rather than restating the obvious
- Links to source documentation included where relevant: `-- Source: https://...`

## Keymap Conventions

**All keymaps include `desc` attribute:**
- Global keymaps: `{ desc = "Move to left split" }` in `lua/config/keymaps.lua`
- Plugin keymaps: `desc = "Toggle file tree"` in `keys` table entries
- LSP keymaps: `desc = "LSP: [G]oto [D]efinition"` with bracket notation for mnemonics

**Leader-key grouping:**
- `<leader>b` -- Buffer management
- `<leader>e` -- Explorer/file tree
- `<leader>f` -- Format
- `<leader>g` -- Git
- `<leader>h` -- Help
- `<leader>t` -- Terminal
- `<leader>x` -- Diagnostics
- Groups registered in `lua/plugins/qol.lua` via which-key `opts.spec`

**LSP keymaps use `g` prefix (not leader):**
- `gd`, `gr`, `gR`, `gD`, `gi`, `go`, `ga` -- all in `lua/plugins/lsp.lua`
- Buffer-scoped via `{ buffer = event.buf }`

## Error Handling

**Patterns:**
- `pcall()` for operations that may fail: `pcall(vim.api.nvim_win_set_cursor, 0, mark)` in `lua/config/autocmds.lua`
- Guard checks before API calls: `if help_win and vim.api.nvim_win_is_valid(help_win)` in `lua/config/helpscreen.lua`
- `vim.v.shell_error ~= 0` check after `vim.fn.system()` calls in `init.lua`
- Graceful exit with user message on bootstrap failure: `vim.api.nvim_echo(...)` + `os.exit(1)` in `init.lua`

## Module Design

**Exports:**
- Plugin files export a table (lazy.nvim spec format): `return { ... }`
- Config modules with state use the `M` pattern: `local M = {} ... return M` (see `lua/config/helpscreen.lua`)
- Config modules without state are side-effect only (no return): `lua/config/options.lua`, `lua/config/keymaps.lua`, `lua/config/autocmds.lua`

**Barrel Files:**
- Not used. lazy.nvim auto-discovery replaces the need for barrel files

---

*Convention analysis: 2026-03-08*
