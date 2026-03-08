# Architecture

**Analysis Date:** 2026-03-08

## Pattern Overview

**Overall:** Neovim Lua configuration using lazy.nvim plugin manager with modular file-per-concern structure.

**Key Characteristics:**
- Single entry point (`init.lua`) bootstraps leader key, config modules, and lazy.nvim
- Core config (options, keymaps, autocmds) loads synchronously before any plugins
- Plugins are auto-discovered from `lua/plugins/` directory by lazy.nvim's `{ import = "plugins" }` spec
- Each plugin file returns a lazy.nvim spec table (or list of spec tables) -- no imperative setup calls at module scope except where required (e.g., `vim.diagnostic.config()` in `lua/plugins/lsp.lua`)

## Layers

**Bootstrap Layer:**
- Purpose: Set leader key, load config modules, bootstrap and initialize lazy.nvim
- Location: `init.lua`
- Contains: Leader key assignment, `require()` calls for config modules, lazy.nvim git clone + setup
- Depends on: Nothing (first code to run)
- Used by: Everything downstream

**Core Config Layer:**
- Purpose: Editor behavior independent of any plugin -- options, keymaps, autocommands, help screen
- Location: `lua/config/`
- Contains: Vim option settings, global keymaps, autocommands, custom help screen module
- Depends on: Neovim API only (`vim.*`)
- Used by: Plugin layer (plugins inherit options like `termguicolors`, `expandtab`)

**Plugin Layer:**
- Purpose: Third-party plugin declarations with lazy-loading specs and configuration
- Location: `lua/plugins/`
- Contains: One file per functional concern, each returning a lazy.nvim spec table
- Depends on: Core Config Layer (options must be set first), lazy.nvim runtime
- Used by: Neovim runtime (plugins hook into events, keymaps, commands)

## Data Flow

**Startup Sequence:**

1. `init.lua` sets `vim.g.mapleader` and `vim.g.maplocalleader` to Space
2. `require("config.options")` sets all `vim.opt.*` values (line numbers, indentation, search, etc.)
3. `require("config.keymaps")` registers global keymaps (window nav, buffer management)
4. `require("config.autocmds")` creates autocommand groups (yank highlight, cursor restore, whitespace strip, filetype overrides)
5. `require("config.helpscreen").setup()` registers `<leader>h` keymap and VimEnter autocmd for startup help popup
6. lazy.nvim bootstraps itself (git clone if missing), then `require("lazy").setup()` scans `lua/plugins/` and loads/lazy-loads all plugin specs

**LSP Initialization Flow:**

1. `lua/plugins/lsp.lua` file-level code runs `vim.diagnostic.config()` and creates `LspAttach`/`CursorHold` autocmds
2. mason.nvim installs missing servers from `ensure_installed` list
3. `vim.lsp.config()` sets per-server options (yamlls, jsonls, lua_ls) BEFORE `mason-lspconfig.setup()`
4. `automatic_enable = true` in mason-lspconfig calls `vim.lsp.enable()` for each installed server
5. blink.cmp (loaded as dependency) patches `vim.lsp.config['*'].capabilities` for completion support
6. On `LspAttach` event: buffer-scoped keymaps (gd, gr, K, gR, ga, gD, gi, go) are registered

**Formatting Pipeline:**

1. conform.nvim hooks into `BufWritePre` (format-on-save) and `<leader>f` (manual format)
2. Formatter selected by filetype from `formatters_by_ft` mapping
3. If no conform formatter configured for filetype, falls back to LSP formatter (`lsp_format = "fallback"`)

**Linting Pipeline:**

1. nvim-lint triggers on `BufReadPost` and `BufWritePost` via `project-lint` augroup
2. Linter selected by filetype from `linters_by_ft` mapping
3. Diagnostics merge with LSP diagnostics in vim.diagnostic system

**State Management:**
- No custom state management -- plugins use their own internal state
- Buffer-local variables used for cross-plugin communication (e.g., `vim.b.gitsigns_status_dict` read by lualine)
- Module-level locals used for UI state in `lua/config/helpscreen.lua` (`help_buf`, `help_win`, `auto_close_timer`)

## Key Abstractions

**Lazy.nvim Plugin Spec:**
- Purpose: Declarative plugin configuration with lazy-loading triggers
- Examples: Every file in `lua/plugins/` returns one
- Pattern: `opts` style preferred (plain table passed to plugin's `setup()`). `config` function used only when imperative code is required (e.g., `lua/plugins/lsp.lua`, `lua/plugins/treesitter.lua`, `lua/plugins/linting.lua`)

**Autocommand Groups (augroups):**
- Purpose: Namespace autocommands to prevent duplicates on config reload
- Examples: `project-lsp-attach` in `lua/plugins/lsp.lua`, `project-lint` in `lua/plugins/linting.lua`, `highlight_yank`/`restore_cursor`/`strip_whitespace`/`json_conceal`/`filetype_indent` in `lua/config/autocmds.lua`
- Pattern: `vim.api.nvim_create_augroup("name", { clear = true })` -- always with `clear = true`

**Keymap Registration:**
- Purpose: Bind keys to actions with description metadata
- Examples: `lua/config/keymaps.lua` (global), `lua/plugins/lsp.lua` (buffer-scoped on LspAttach), `lua/plugins/git.lua` (buffer-scoped on_attach)
- Pattern: `vim.keymap.set(mode, key, action, { desc = "..." })` -- always include `desc` for which-key discovery

## Entry Points

**`init.lua`:**
- Location: `init.lua`
- Triggers: Neovim startup
- Responsibilities: Set leader key, load config modules in order, bootstrap lazy.nvim, initialize all plugins

**`lua/config/helpscreen.lua`:**
- Location: `lua/config/helpscreen.lua`
- Triggers: Called via `require("config.helpscreen").setup()` from `init.lua`
- Responsibilities: Only config module that exposes a `setup()` function; registers keymap and startup autocmd

## Error Handling

**Strategy:** Minimal explicit error handling; relies on Neovim and plugin defaults.

**Patterns:**
- `pcall(vim.api.nvim_win_set_cursor, ...)` in `lua/config/autocmds.lua` for safe cursor restore
- lazy.nvim bootstrap checks `vim.v.shell_error` and displays error message before `os.exit(1)` in `init.lua`
- No try/catch patterns in plugin configs -- errors propagate to Neovim's error handler

## Cross-Cutting Concerns

**Logging:** Not configured. Uses Neovim's built-in `:messages` and plugin-specific logging (e.g., `:ConformInfo`, `:LspInfo`, `:Mason`).

**Validation:** Schema validation for JSON and YAML files provided by SchemaStore.nvim integration with jsonls and yamlls servers (`lua/plugins/lsp.lua`).

**Authentication:** Not applicable (editor configuration).

**Tool Installation:** Mason ecosystem auto-installs LSP servers (`lua/plugins/lsp.lua` via mason-lspconfig), formatters, and linters (`lua/plugins/linting.lua` via mason-tool-installer) on first launch.

**Filetype Mapping:** Both formatting (`lua/plugins/formatting.lua`) and linting (`lua/plugins/linting.lua`) explicitly map both `sh` and `bash` filetypes because Neovim assigns different filetypes based on shebang presence.

---

*Architecture analysis: 2026-03-08*
