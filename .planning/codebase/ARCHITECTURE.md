# Architecture

**Analysis Date:** 2026-03-09

## Pattern Overview

**Overall:** Modular Neovim configuration using lazy.nvim plugin manager with convention-based auto-discovery.

**Key Characteristics:**
- Single entry point (`init.lua`) bootstraps lazy.nvim and requires config modules in explicit order
- Plugin specs live as individual Lua files in `lua/plugins/`, auto-discovered by lazy.nvim's `{ import = "plugins" }` pattern
- Core editor settings (options, keymaps, autocmds) are separated from plugin configuration in `lua/config/`
- Each plugin file is a self-contained lazy.nvim spec returning a table (or list of tables)
- Load order is managed via lazy.nvim's `dependencies` declarations and `event`/`cmd`/`keys` lazy-loading triggers

## Layers

**Core Configuration Layer:**
- Purpose: Set editor-wide options, keymaps, and autocommands before any plugins load
- Location: `lua/config/`
- Contains: `options.lua` (vim.opt settings), `keymaps.lua` (non-plugin keybindings), `autocmds.lua` (global autocommands), `helpscreen.lua` (startup help overlay)
- Depends on: Neovim runtime only (vim.opt, vim.keymap, vim.api)
- Used by: All plugins inherit these base settings (e.g., `termguicolors` must be set before colorscheme loads)

**Plugin Specification Layer:**
- Purpose: Declare, configure, and lazy-load all third-party plugins
- Location: `lua/plugins/`
- Contains: One file per plugin concern (e.g., `lsp.lua`, `completion.lua`, `git.lua`); each returns a lazy.nvim spec table
- Depends on: lazy.nvim plugin manager, core config layer (leader key, options)
- Used by: Neovim runtime via lazy.nvim auto-discovery

**Plugin Manager Bootstrap:**
- Purpose: Clone lazy.nvim if missing, prepend to runtimepath, call `lazy.setup()`
- Location: `init.lua` (lines 12-41)
- Contains: Git clone logic, rtp manipulation, lazy.setup() call
- Depends on: Git binary on PATH
- Used by: Neovim on startup

## Data Flow

**Startup Sequence:**

1. `init.lua` sets `vim.g.mapleader` to Space (must happen before any keymap or plugin)
2. `require("config.options")` applies vim.opt settings (line numbers, indentation, termguicolors, etc.)
3. `require("config.keymaps")` registers non-plugin keymaps (window navigation, buffer management)
4. `require("config.autocmds")` registers global autocommands (yank highlight, cursor restore, whitespace strip, filetype overrides)
5. `require("config.helpscreen").setup()` registers `<leader>h` keymap and VimEnter autocmd for startup help overlay
6. lazy.nvim bootstrap: clone if missing, prepend to runtimepath
7. `require("lazy").setup({ spec = { { import = "plugins" } } })` scans `lua/plugins/*.lua`, resolves dependencies, loads eager plugins, registers lazy-load triggers

**LSP Initialization Flow:**

1. `lua/plugins/lsp.lua` executes top-level code immediately when loaded by lazy.nvim: `vim.diagnostic.config()` and two autocmds (CursorHold diagnostic float, LspAttach keymaps)
2. `mason-lspconfig.nvim` `config` function runs: calls `vim.lsp.config()` for servers needing custom settings (yamlls, jsonls, lua_ls), then `require("mason-lspconfig").setup(opts)`
3. `automatic_enable = true` causes mason-lspconfig to call `vim.lsp.enable(name)` for each installed server
4. On file open matching a server's filetype, Neovim attaches the LSP client, firing `LspAttach` autocmd which registers buffer-scoped keymaps (gd, gr, K, etc.)

**Completion Flow:**

1. `blink.cmp` loads before `nvim-lspconfig` (declared as dependency in `lsp.lua`)
2. blink.cmp patches `vim.lsp.config['*'].capabilities` to advertise completion support
3. When LSP attaches, it reads patched capabilities and sends completions to blink.cmp
4. Sources priority: lazydev (Lua API, score_offset=100) > lsp > path > snippets > buffer

**Formatting Flow:**

1. conform.nvim hooks into `BufWritePre` event via `format_on_save` config
2. On save: conform checks `formatters_by_ft` for matching formatter
3. If found: runs the configured formatter(s) sequentially (e.g., Python runs ruff_fix, ruff_format, ruff_organize_imports)
4. If no formatter configured: falls back to LSP formatting (`lsp_format = "fallback"`)
5. Manual trigger: `<leader>f` calls `require("conform").format({ async = true })`

**Linting Flow:**

1. nvim-lint loaded on `BufReadPost` and `BufWritePost` events
2. `project-lint` augroup autocmd calls `lint.try_lint()` on the same events
3. nvim-lint looks up `linters_by_ft` for the buffer's filetype
4. Runs the linter binary asynchronously, publishes results as vim diagnostics alongside LSP diagnostics

**State Management:**
- No global state management; each plugin manages its own state
- Buffer-local variables used for cross-plugin communication (e.g., `vim.b.gitsigns_status_dict` read by lualine's `diff_source` function in `lua/plugins/statusline.lua`)
- Keymaps use buffer-scoped bindings for LSP (`buffer = event.buf`) and gitsigns (`opts.buffer = bufnr`)

## Key Abstractions

**Plugin Spec Pattern:**
- Purpose: Encapsulate all configuration for a plugin concern in a single file
- Examples: `lua/plugins/lsp.lua`, `lua/plugins/completion.lua`, `lua/plugins/formatting.lua`
- Pattern: Each file returns a Lua table (or list of tables) conforming to lazy.nvim's plugin spec format. Uses `opts` style for declarative config; `config` function only when imperative setup is required (lsp.lua, linting.lua, treesitter.lua).

**Config Module Pattern:**
- Purpose: Separate non-plugin editor configuration into focused files
- Examples: `lua/config/options.lua`, `lua/config/keymaps.lua`, `lua/config/autocmds.lua`
- Pattern: Each file is a plain Lua script that runs side-effects on `require()`. No return value except `helpscreen.lua` which returns a module table with a `setup()` method.

**Lazy-Loading Triggers:**
- Purpose: Defer plugin loading until needed to minimize startup time
- Examples: `event = "InsertEnter"` (autopairs), `keys = { "<leader>e" }` (neo-tree), `cmd = "Trouble"` (trouble.nvim), `ft = "lua"` (lazydev)
- Pattern: Every plugin that is not needed at startup uses at least one lazy-loading trigger. Only `colorscheme.lua` (`lazy = false, priority = 1000`), `treesitter.lua` (`lazy = false`), and `vim-fugitive` (`lazy = false`) load eagerly.

**Augroup Naming Convention:**
- Purpose: Prevent duplicate autocommands on config reload
- Examples: `"highlight_yank"`, `"project-lsp-attach"`, `"project-lint"`, `"project-diag-float"`
- Pattern: All autocommands use named augroups with `clear = true`. Config-level augroups use descriptive names; plugin-level augroups use `project-` prefix.

## Entry Points

**`init.lua`:**
- Location: `init.lua`
- Triggers: Neovim startup
- Responsibilities: Set leader key, load config modules in order, bootstrap lazy.nvim, initialize plugin system

**`lua/plugins/*.lua` (each file):**
- Location: `lua/plugins/`
- Triggers: lazy.nvim auto-discovery via `{ import = "plugins" }`
- Responsibilities: Return plugin spec(s) for one logical concern

## Error Handling

**Strategy:** Minimal explicit error handling; relies on Neovim and lazy.nvim defaults.

**Patterns:**
- lazy.nvim bootstrap failure: displays error message via `nvim_echo` and exits with `os.exit(1)` (in `init.lua`)
- Cursor restore: wraps `nvim_win_set_cursor` in `pcall()` to silently handle invalid marks (`lua/config/autocmds.lua` line 18)
- Navic breadcrumbs: checks `navic.is_available()` before calling `get_location()` (`lua/plugins/statusline.lua` lines 91-97)
- No try/catch or error propagation patterns; plugin crashes surface as Neovim error messages

## Cross-Cutting Concerns

**Logging:** Not applicable. No custom logging. Neovim's built-in `:messages` and notification system used.

**Validation:** Schema validation for JSON and YAML files provided by SchemaStore.nvim integration in `lua/plugins/lsp.lua`. Static analysis by nvim-lint per `linters_by_ft` in `lua/plugins/linting.lua`.

**Authentication:** Not applicable (editor configuration, no network auth).

**Tool Installation:** Centralized in two places:
- LSP servers: `ensure_installed` list in `lua/plugins/lsp.lua` (mason-lspconfig)
- Formatters and linters: `ensure_installed` list in `lua/plugins/linting.lua` (mason-tool-installer)

**Dependency Graph (critical load order):**
- `blink.cmp` MUST load before `nvim-lspconfig` (capabilities patching)
- `vim.lsp.config()` calls MUST run before `mason-lspconfig.setup()` (per-server settings)
- `lazydev.nvim` MUST be declared before `blink.cmp` in `completion.lua` (source provider registration)
- `nvim-navic` MUST load before `lualine.nvim` (winbar breadcrumb provider)

---

*Architecture analysis: 2026-03-09*
