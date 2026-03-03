# Architecture

**Analysis Date:** 2026-03-03

## Pattern Overview

**Overall:** Modular Lua configuration using lazy.nvim plugin manager with clear separation of concerns between core config (options, keymaps, autocmds) and functional plugin layers.

**Key Characteristics:**
- Plugin-driven: lazy.nvim auto-discovers plugin specs from `lua/plugins/` directory
- Configuration-first: all vim options, keymaps, and autocmds load before lazy.nvim bootstrap
- Explicit load ordering: dependency declarations and event-based triggers control plugin initialization sequence
- Diagnostic-centric: LSP diagnostics, linting, formatting integrated as first-class concerns
- Modular vertical slicing: each plugin category (LSP, completion, git, etc.) is self-contained

## Layers

**Core Configuration:**
- Purpose: Establish editor baseline state before any plugins initialize
- Location: `lua/config/`
- Contains: vim options, global keymaps, autocmds, mapleader setup
- Depends on: Neovim native API (vim.opt, vim.keymap, vim.api)
- Used by: Entry point (`init.lua`) loads these before lazy.nvim bootstrap
- Key files:
  - `lua/config/options.lua` - line numbers, indentation, scrolling, search behavior
  - `lua/config/keymaps.lua` - window navigation, buffer management, search clear
  - `lua/config/autocmds.lua` - yank highlight, cursor restore, whitespace strip, filetype-specific indentation

**Plugin Layer:**
- Purpose: Extend editor with LSP, completion, formatting, linting, version control, UI enhancements
- Location: `lua/plugins/`
- Contains: lazy.nvim plugin specs (return tables with deps, opts, keys, events, etc.)
- Depends on: Core config, lazy.nvim plugin manager, external packages (mason.nvim, blink.cmp, etc.)
- Used by: lazy.nvim auto-discovers all `.lua` files in this directory via `{ import = "plugins" }`
- Structure: Each concern gets its own file (lsp.lua, completion.lua, formatting.lua, etc.)

**Language Server Protocol (LSP):**
- Purpose: Provide language intelligence (diagnostics, goto-definition, hover, rename) for 8 languages
- Location: `lua/plugins/lsp.lua`
- Core components:
  - `vim.diagnostic.config()` - severity sort, diagnostic float on hover, sign text (E/W/I/H)
  - `vim.api.nvim_create_autocmd("LspAttach", ...)` - buffer-scoped keymaps (gd, gr, K, gR, ga, gD, gi, go)
  - `mason-lspconfig.nvim` - auto-installs 8 language servers (clangd, pyright, lua_ls, bashls, yamlls, dockerls, terraformls, jsonls, rust_analyzer)
  - Per-server `vim.lsp.config()` calls for yamlls, jsonls, lua_ls with SchemaStore integration and Lua runtime context
- Load order: Diagnostic config runs immediately; LspAttach autocmd hooks when first server attaches; per-server config runs before mason-lspconfig.setup()

**Completion & Snippets:**
- Purpose: Intelligent code completion with LSP sources, snippet expansion, and Lua API awareness
- Location: `lua/plugins/completion.lua`
- Core components:
  - `blink.cmp` - completion engine with Rust fuzzy matching, ghosts text preview, Tab/Enter/Right keymaps
  - `lazydev.nvim` - Lua file-only completion for vim.*, vim.uv, vim.fn (lazy-loaded on ft=lua)
  - `friendly-snippets` - VSCode-compatible snippet library auto-loaded by blink.cmp
- Source order: lazydev (Lua only, score_offset=100) → LSP → path → snippets → buffer
- Load order: lazydev must be processed before blink.cmp; blink.cmp must load before LSP server startup

**Formatting & Code Style:**
- Purpose: Format code on save using language-specific formatters
- Location: `lua/plugins/formatting.lua`
- Core components:
  - `conform.nvim` - format-on-save orchestration via BufWritePre event
  - Formatter mapping: clang-format (C/C++), ruff chain (Python), stylua (Lua), shfmt (Bash/sh), prettier (YAML/JSON), terraform_fmt (Terraform), rustfmt (Rust)
  - LSP fallback when no conform formatter configured
  - Manual format trigger: `<leader>f` (normal and visual range)
- Load order: Lazy-loaded on BufWritePre event; ConformInfo command also available

**Linting & Diagnostics Combination:**
- Purpose: Async per-filetype linting alongside LSP diagnostics; navigable diagnostic UI
- Location: `lua/plugins/linting.lua` (linters) and `lua/plugins/diagnostics.lua` (UI)
- Core components:
  - `mason-tool-installer.nvim` - auto-installs all formatter and linter binaries
  - `nvim-lint` - async linter with linters_by_ft mapping; fires on BufReadPost/BufWritePost
  - `trouble.nvim` - navigable project/buffer diagnostics panel (`:Trouble diagnostics toggle`)
  - `fidget.nvim` - non-intrusive LSP progress spinner (bottom-right, auto-fade)
- Linters: cpplint (C/C++), ruff (Python), luacheck (Lua), shellcheck (Bash/sh), yamllint (YAML), hadolint (Dockerfile), tflint (Terraform), jsonlint (JSON)

**Syntax Trees & Text Objects:**
- Purpose: Language-aware text navigation, selection, and indentation via Treesitter
- Location: `lua/plugins/treesitter.lua`
- Core components:
  - `nvim-treesitter` (branch=master) - syntax highlighting, indentation, incremental selection
  - `nvim-treesitter-textobjects` (branch=master) - af/if (function), ac/ic (class), aa/ia (parameter)
  - 12 parser targets: c, cpp, python, lua, bash, yaml, hcl, json, rust, dockerfile, cmake, make
  - sync_install=false, auto_install=false - explicit, non-blocking
- Load order: Not lazy-loadable (plugin docs); `:TSUpdate` compiles parsers on first setup

**Version Control Integration:**
- Purpose: Inline git diffs, blame information, and git command interface
- Location: `lua/plugins/git.lua`
- Core components:
  - `gitsigns.nvim` - gutter diff signs (┃ add, ┃ change, _ delete, ‾ topdelete, ~ changedelete, ┆ untracked)
  - Inline blame toggle via `<leader>gb` (virtual text at EOL, persistent)
  - `vim-fugitive` - `:Git` command interface (NOT lazy-loaded; registers autocommands at startup)
- Load order: gitsigns lazy-loads on BufReadPost/BufNewFile; vim-fugitive loads immediately

**File Tree & Buffer Management:**
- Purpose: Navigable file tree with git status overlay and buffer switcher
- Location: `lua/plugins/filetree.lua`
- Core components:
  - `neo-tree.nvim` (branch=v3.x) - dual-source file tree and buffers panel
  - Filesystem source: follow current file, libuv watcher, show dotfiles and gitignored files
  - Buffers source: show unloaded buffers, follow current file
  - Left sidebar (35 chars wide), git status as floating window
- Keys: `<leader>e` or `\` toggle file tree; `<leader>b` toggle buffers panel
- Load order: Lazy-loads on first key press

**Integrated Terminal:**
- Purpose: Toggleable horizontal terminal at bottom 1/3 of viewport
- Location: `lua/plugins/terminal.lua`
- Core components:
  - `toggleterm.nvim` - horizontal full-width terminal, 33% window height
  - Insert mode at startup, terminal shading enabled
  - Persistent size: false (always recalculates to 33%)
- Key: `<leader>t` toggles terminal
- Load order: Lazy-loads on first key press

**Statusline & Breadcrumbs:**
- Purpose: Display editor state (mode, file, LSP status), git context, and LSP breadcrumbs
- Location: `lua/plugins/statusline.lua`
- Core components:
  - `lualine.nvim` - statusline engine with globalstatus=true (single bar across all splits)
  - Sections: mode | branch + gitsigns diff + diagnostics | filename + modified | lsp_status + filetype | progress | location:column
  - Winbar breadcrumbs via `nvim-navic` (LSP-backed function/class path, depth_limit=5)
  - Theme: tokyonight (matches colorscheme)
  - Custom diff_source maps gitsigns.changed → lualine modified
- Load order: nvim-navic loads first (auto_attach on LspAttach); lualine loads after with navic dependency declared

**Quality-of-Life Enhancements:**
- Purpose: Keymap discoverability, visual indentation, auto-pairing
- Location: `lua/plugins/qol.lua`
- Core components:
  - `which-key.nvim` - keymap popup on leader-key pause; v3 API with spec groups
  - `indent-blankline.nvim` - indent guides with treesitter scope underline
  - `nvim-autopairs` - auto-close brackets/quotes on keystroke; treesitter-aware
- Load order: which-key loads on VeryLazy; indent-blankline on VeryLazy; autopairs on InsertEnter

**Colorscheme:**
- Purpose: Set editor theme and terminal ANSI colors
- Location: `lua/plugins/colorscheme.lua`
- Core component: `tokyonight.nvim` (style=night, darkest variant)
- Load order: lazy=false, priority=1000 (loads before all other plugins)

**Dependencies (Shared):**
- Purpose: Provide common Lua utilities used by multiple plugins
- Location: `lua/plugins/deps.lua`
- Packages: nvim-web-devicons (file icons), plenary.nvim (async utilities), nui.nvim (UI library)

## Data Flow

**Editor Startup:**

1. `init.lua` runs: sets mapleader, requires core config modules, bootstraps lazy.nvim
2. Core config loads synchronously: options.lua → keymaps.lua → autocmds.lua
3. lazy.nvim bootstrap: clones if missing, prepends to rtp, calls setup()
4. lazy.nvim setup: discovers `lua/plugins/*.lua`, processes specs in order
5. Colorscheme loads first (priority=1000, lazy=false)
6. Dependencies load (lazy=true, deferred)
7. Plugins load based on events/keys (BufReadPost, BufWritePre, VeryLazy, etc.)
8. When LSP file opens:
   - nvim-treesitter parser loads (syntax highlighting, indentation)
   - LSP servers attach via mason-lspconfig (automatic_enable=true)
   - LspAttach autocmd fires: registers buffer-scoped keymaps, nvim-navic auto-attaches
   - blink.cmp patches LSP capabilities (must load before server startup)
   - gitsigns attaches (BufReadPost event)
   - nvim-lint tries_lint on file load
   - conform waits for next BufWritePre to format
9. When user types: autopairs inserts closing brackets; blink.cmp shows completions
10. When user saves: conform formats; nvim-lint runs async linting

**LSP Lifecycle:**

1. User opens file → treesitter parser loads
2. lazy.nvim loads lsp.lua (on-demand)
3. vim.diagnostic.config() applies globally (runs immediately at module load)
4. Per-server vim.lsp.config() calls applied (yamlls, jsonls, lua_ls)
5. mason-lspconfig.setup() triggers vim.lsp.enable(server_name) for each ensure_installed
6. Server process starts; sends $/progress notifications
7. First diagnostic received → LspAttach autocmd fires
8. Buffer-scoped keymaps registered (gd, gr, K, gR, ga, gD, gi, go)
9. nvim-navic observes LSP attachments → subscribes to document symbols
10. lualine reads lsp_status component → shows active server name
11. fidget.nvim listens to $/progress notifications → displays spinner

**Completion Flow:**

1. User enters InsertMode or presses trigger key
2. blink.cmp queries sources in order: lazydev (Lua files only) → LSP (if attached) → path → snippets → buffer
3. LSP source sends textDocument/completion RPC to language server
4. Server returns completion items; blink.cmp fuzzy-ranks (Rust engine)
5. User presses Tab/Enter/Right:
   - Tab navigates items or expands snippet
   - Enter accepts item
   - Right accepts and falls back to normal keystroke (VSCode feel)
6. Selected completion triggers LSP textDocument/didChange → server re-diagnoses
7. diagnostics updated → lualine refreshes diagnostic count

**Formatting & Linting Flow:**

1. User saves buffer (BufWritePre event)
2. conform.format_on_save triggers: queries formatters_by_ft
3. If conform formatter found: runs formatter, applies edits
4. If not found: LSP fallback (lsp_format="fallback")
5. Simultaneously (BufWritePost): nvim-lint.try_lint() runs async
6. Linters produce diagnostics → vim.diagnostic.set() merges with LSP diagnostics
7. trouble.nvim re-renders if visible
8. lualine refreshes diagnostic count in statusline

**Git Interaction:**

1. File opens in buffer → gitsigns attaches (BufReadPost)
2. gitsigns queries git diff → renders change/add/delete signs in gutter
3. User presses `<leader>gb` → gitsigns.toggle_current_line_blame()
4. Blame info fetched → virtual text inserted at EOL: "<author>, <time> - <summary>"
5. Git blame updates on cursor move (current_line_blame formatter re-triggers)
6. lualine reads vim.b.gitsigns_status_dict → displays branch + diff stats

## Key Abstractions

**Plugin Spec Pattern:**
- Purpose: Declarative plugin configuration with lazy.nvim
- Examples: `lua/plugins/*.lua` (all files)
- Pattern: Each returns a table (or table of tables) with {name, lazy, event, keys, opts, config, dependencies}
  - lazy = false: load immediately
  - event = "BufReadPost" or similar: load on event
  - keys = {...}: load when keymap pressed
  - opts = {...}: pass config to plugin setup function
  - config = function: custom initialization logic

**Autocmd Pattern:**
- Purpose: Hook into Neovim events with named augroups
- Examples: `lua/config/autocmds.lua` (core), `lua/plugins/lsp.lua` (LspAttach), `lua/plugins/linting.lua` (BufReadPost/BufWritePost)
- Pattern: vim.api.nvim_create_autocmd(event, {group = augroup_name, clear=true, callback = fn})
  - Named augroups: safe reload (clear=true prevents duplicates)
  - Buffer-scoped: event.buf used for LSP buffer keymaps
  - Clear=true: idempotent on config reload

**Lazy-Loading Trigger Pattern:**
- Purpose: Defer plugin initialization until needed
- Examples: All plugins in `lua/plugins/`
- Triggers:
  - event = "BufReadPost": general file read
  - event = "InsertEnter": completion, autopairs
  - cmd = "ConformInfo": on-demand via command
  - keys = {...}: on keypress
  - lazy = false: immediate (colorscheme, vim-fugitive)

**Per-Server LSP Config Pattern:**
- Purpose: Language-specific server settings before automatic enable
- Examples: yamlls, jsonls, lua_ls in `lua/plugins/lsp.lua`
- Pattern: vim.lsp.config(server_name, {settings = {...}}) called BEFORE mason-lspconfig.setup()
  - SchemaStore integration for yamlls/jsonls (disable built-in, use SchemaStore.nvim)
  - Lua runtime context for lua_ls (VIMRUNTIME library)
  - Must run before mason-lspconfig.setup() so automatic_enable picks them up

**Dependency Ordering:**
- Purpose: Ensure plugins load in correct sequence
- Examples: blink.cmp (must load before LSP), nvim-navic (must load before lualine)
- Pattern: dependencies = {...} in plugin spec
  - lazy.nvim processes dependencies before the plugin using them
  - blink.cmp declared as dependency of mason-lspconfig to patch capabilities first
  - nvim-navic auto_attach waits for LspAttach, lualine winbar waits for navic

**Dual-Source neotree Pattern:**
- Purpose: Unified tree UI with different data backends
- Examples: `lua/plugins/filetree.lua`
- Pattern: Same keybind toggles different source (filesystem vs buffers)
  - `<leader>e` / `\`: Neotree source=filesystem
  - `<leader>b`: Neotree source=buffers

## Entry Points

**`init.lua`:**
- Location: `/home/cmyster/work-laptop/rc_files/.config/nvim/init.lua`
- Triggers: Runs when Neovim starts (before loading buffers or processing plugins)
- Responsibilities:
  1. Set vim.g.mapleader and vim.g.maplocalleader (MUST be first)
  2. Require core config modules (options, keymaps, autocmds)
  3. Bootstrap lazy.nvim (clone if missing, set rtp, call setup)
  4. Lazy.nvim auto-discovers `lua/plugins/*.lua`

**LSP Attachment:**
- Event: LspAttach (fires when first LSP server attaches to a buffer)
- Handler: vim.api.nvim_create_autocmd("LspAttach", ...) in `lua/plugins/lsp.lua`
- Responsibilities:
  1. Register buffer-scoped keymaps (gd, gr, K, gR, ga, gD, gi, go)
  2. nvim-navic auto-attaches (via auto_attach=true)
  3. lualine reads lsp_status (populated by nvim-lspconfig)

**File Open (BufReadPost):**
- Event: BufReadPost (fires after file content loaded into buffer)
- Handlers: cursor restoration, gitsigns attach, treesitter parse, nvim-lint
- Responsibilities:
  1. Restore cursor position (autocmd in `lua/config/autocmds.lua`)
  2. gitsigns attaches (event trigger in `lua/plugins/git.lua`)
  3. nvim-lint.try_lint() runs (event trigger in `lua/plugins/linting.lua`)
  4. Treesitter parser loads (lazy.nvim auto-loads `lua/plugins/treesitter.lua` on first file)

**File Save (BufWritePre):**
- Event: BufWritePre (fires before buffer written to disk)
- Handlers: conform.format_on_save, whitespace stripping
- Responsibilities:
  1. Strip trailing whitespace (autocmd in `lua/config/autocmds.lua`)
  2. conform.format_on_save runs (event trigger in `lua/plugins/formatting.lua`)

## Error Handling

**Strategy:** Fail-open with diagnostic visibility; no silent failures

**Patterns:**
- Diagnostic floats: vim.diagnostic.float() on CursorHold (hover displays errors)
- LSP server failures: trouble.nvim lists all diagnostics (`:Trouble diagnostics toggle`)
- Formatter failures: conform logs via :ConformInfo; falls back to LSP if available
- Linter failures: conform.nvim silently skips unknown formatter names (no error, just skipped)
- Mason failures: Server list shows failed installs; manual `:MasonInstall` available

## Cross-Cutting Concerns

**Logging:** Console output via vim.notify() (Neovim's built-in notification system); no custom logger

**Validation:**
- LSP provides type checking and linting diagnostics
- nvim-lint provides per-language linting (ruff, shellcheck, etc.)
- conform ensures formatters exist via :ConformInfo

**Authentication:** Not applicable (local editor config); git authentication via SSH keys or system credentials

**Performance:**
- Lazy-loading minimizes startup time (only load plugins when needed)
- Async operations: conform (async=true), nvim-lint (BufWritePost async), treesitter (sync_install=false)
- Fuzzy matching: blink.cmp prefers Rust engine (prefer_rust_with_warning)
- LSP progress: fidget.nvim non-blocking spinner display

---

*Architecture analysis: 2026-03-03*
