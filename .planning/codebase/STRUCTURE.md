# Codebase Structure

**Analysis Date:** 2026-03-03

## Directory Layout

```
~/.config/nvim/
├── init.lua                   # Entry point: bootstrap lazy.nvim, load core config
├── lazy-lock.json             # Lock file: pinned plugin versions and commits
└── lua/
    ├── config/
    │   ├── options.lua        # Editor options: lines, indentation, scrolling, search, files
    │   ├── keymaps.lua        # Global keymaps: window navigation, buffer mgmt, search
    │   └── autocmds.lua       # Autocmds: yank highlight, cursor restore, whitespace strip, filetype indent
    └── plugins/
        ├── deps.lua           # Shared dependencies: web-devicons, plenary, nui
        ├── colorscheme.lua    # Colorscheme: tokyonight-night theme
        ├── lsp.lua            # LSP: mason-lspconfig, nvim-lspconfig, 8 language servers, per-server config
        ├── completion.lua     # Completion: blink.cmp, lazydev, friendly-snippets
        ├── formatting.lua     # Formatting: conform.nvim, 7 language formatters
        ├── linting.lua        # Linting: mason-tool-installer, nvim-lint, 8 linters
        ├── diagnostics.lua    # Diagnostics UI: trouble.nvim, fidget.nvim
        ├── treesitter.lua     # Syntax trees: nvim-treesitter, textobjects, 12 parsers
        ├── git.lua            # Version control: gitsigns, vim-fugitive
        ├── filetree.lua       # File tree: neo-tree (v3.x), filesystem + buffers sources
        ├── terminal.lua       # Integrated terminal: toggleterm (horizontal, 33% height)
        ├── statusline.lua     # Status display: lualine, nvim-navic breadcrumbs
        ├── qol.lua            # Quality-of-life: which-key, indent-blankline, autopairs
```

## Directory Purposes

**`lua/config/`:**
- Purpose: Core editor configuration that loads before any plugins
- Contains: vim.opt settings, global keymaps, event-driven autocmds
- Key files: `options.lua` (baseline editor feel), `keymaps.lua` (foundational shortcuts), `autocmds.lua` (life-quality features)
- Load timing: Required synchronously in `init.lua` before lazy.nvim bootstrap
- Modification impact: Any change immediately affects editor behavior at startup

**`lua/plugins/`:**
- Purpose: Feature plugins organized by category; lazy.nvim auto-discovers all `.lua` files
- Contains: Plugin specs (lazy.nvim table format) with opts, keys, events, dependencies
- Key structure: Each file returns one plugin spec or array of specs
- Load timing: Deferred by lazy.nvim based on events, keys, or manual setup
- Auto-discovery: lazy.nvim reads `{ import = "plugins" }` in init.lua setup()
- Modification impact: Adding/removing files instantly changes available features; lazy.nvim handles deduplication of dependencies

## Key File Locations

**Entry Points:**

- `init.lua`: Runs at Neovim startup; sets mapleader, loads core config, bootstraps lazy.nvim
- `lua/plugins/colorscheme.lua`: Loads immediately (lazy=false, priority=1000) before any other plugin

**Configuration:**

- `lua/config/options.lua`: Line numbers (absolute + relative), indentation (2 spaces default, 4 for Python/Rust), scrolling (8), search (ignorecase + smartcase), UI (cursorline, colorcolumn, signcolumn, wrap=false)
- `lua/config/keymaps.lua`: Window navigation (Ctrl+hjkl), terminal escape (Esc+Esc), buffer management (`<leader>b` prefix)
- `lua/config/autocmds.lua`: Yank highlight (200ms), cursor restore on file open, trailing whitespace strip, JSON conceallevel fix, per-filetype indent overrides

**Core Logic:**

- `lua/plugins/lsp.lua`: vim.diagnostic.config(), LspAttach autocmd with 8 buffer keymaps (gd, gr, K, gR, ga, gD, gi, go), mason-lspconfig ensure_installed (clangd, pyright, lua_ls, bashls, yamlls, dockerls, terraformls, jsonls, rust_analyzer), per-server vim.lsp.config() for yamlls/jsonls/lua_ls
- `lua/plugins/completion.lua`: blink.cmp engine with opts_extend pattern, lazydev Lua-only source, friendly-snippets source list (LSP > path > snippets > buffer)
- `lua/plugins/formatting.lua`: conform.nvim with formatters_by_ft mapping for 7 languages, format_on_save on BufWritePre, `<leader>f` manual format (normal + visual)
- `lua/plugins/linting.lua`: mason-tool-installer ensure_installed list (9 tools), nvim-lint with linters_by_ft mapping for 8 languages, async BufReadPost/BufWritePost trigger
- `lua/plugins/treesitter.lua`: ensure_installed list (12 parsers: c, cpp, python, lua, bash, yaml, hcl, json, rust, dockerfile, cmake, make), highlight, indent, incremental_selection, textobjects (af/if/ac/ic/aa/ia keymaps)
- `lua/plugins/git.lua`: gitsigns with change/add/delete signs and inline blame toggle (`<leader>gb`), vim-fugitive with `:Git` command (NOT lazy-loaded)
- `lua/plugins/filetree.lua`: neo-tree v3.x with dual sources (filesystem and buffers), keys: `<leader>e`/`\` (file tree), `<leader>b` (buffers panel)
- `lua/plugins/statusline.lua`: lualine with mode | branch+diff+diags | filename | lsp_status+filetype | progress | location, nvim-navic winbar breadcrumbs, custom diff_source for gitsigns.changed mapping

**Testing:** Not applicable (Neovim config, not application code)

## Naming Conventions

**Files:**

- Pattern: snake_case.lua (all config and plugin files)
- Examples:
  - `init.lua` - entry point
  - `options.lua`, `keymaps.lua`, `autocmds.lua` - core config
  - `lsp.lua`, `completion.lua`, `formatting.lua`, `linting.lua` - plugin categories
  - `git.lua`, `filetree.lua`, `terminal.lua` - feature categories
  - `statusline.lua`, `qol.lua` - UI categories
  - `deps.lua` - shared dependencies

**Directories:**

- Pattern: snake_case (standard Lua project layout)
- Examples:
  - `config/` - core configuration modules
  - `plugins/` - feature plugins auto-discovered by lazy.nvim

**Functions:**

- Pattern: snake_case for local functions, CamelCase for vim.* API calls
- Examples in `lua/config/autocmds.lua`:
  - Local: `local view = vim.fn.winsaveview()` (calling vim function)
  - Local function: `callback = function() ... end` (inside autocmd)
- Examples in `lua/plugins/statusline.lua`:
  - `local function diff_source()` - custom provider for lualine component

**Variables:**

- Pattern: snake_case for locals, camelCase for table keys (Lua convention)
- Examples:
  - `local map = vim.keymap.set` - function alias
  - `local lint = require("lint")` - module alias
  - `local gs = require("gitsigns")` - module alias
  - Table keys: `opts = { ... }`, `keys = { ... }`, `dependencies = { ... }`

**Plugin Spec Keys:**

- Standard lazy.nvim keys: `lazy`, `event`, `keys`, `cmd`, `opts`, `config`, `dependencies`, `ft`, `branch`, `version`, `tag`, `build`, `priority`
- Examples:
  - `lazy = false` - load immediately
  - `event = "BufReadPost"` - load on event
  - `keys = { { "<leader>e", ... } }` - load when key pressed
  - `opts = {}` - options table passed to setup function
  - `config = function()` - custom initialization
  - `dependencies = { "nvim-lua/plenary.nvim" }` - load dependencies first
  - `ft = "lua"` - load only for Lua files
  - `branch = "master"` - pin to branch instead of tag
  - `version = "1.*"` - pin to major version

## Where to Add New Code

**New Feature (complete subsystem):**
- Primary code: Create `lua/plugins/[feature].lua` with plugin spec (lazy.nvim table)
- Return table structure:
  ```lua
  return {
    {
      "[plugin-name]",
      event = "..." or keys = {...} or lazy = false,
      opts = { ... },
      dependencies = { ... },
    },
  }
  ```
- Will auto-load via lazy.nvim's `{ import = "plugins" }` in init.lua
- Tests: Not applicable for Neovim config

**New Global Keymap:**
- Location: `lua/config/keymaps.lua`
- Pattern: `map(mode, key, action, opts)` using vim.keymap.set
- Example: `map("n", "<C-h>", "<C-w>h", { desc = "Move to left split" })`
- Load timing: Runs before lazy.nvim (synchronously from init.lua)

**New Global Autocmd:**
- Location: `lua/config/autocmds.lua`
- Pattern: vim.api.nvim_create_autocmd(event, { group = augroup_name, clear = true, callback = fn })
- Example (from file):
  ```lua
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("strip_whitespace", { clear = true }),
    pattern = "*",
    callback = function() ... end,
  })
  ```
- Augroup naming: Use clear = true for idempotent reload safety

**New Global Editor Option:**
- Location: `lua/config/options.lua`
- Pattern: `opt.setting_name = value` using vim.opt
- Examples: `opt.number = true`, `opt.shiftwidth = 2`
- Load timing: Runs before lazy.nvim (synchronously from init.lua)

**New Per-Filetype Setting:**
- Location: `lua/config/autocmds.lua` (FileType autocmd pattern)
- Pattern: vim.api.nvim_create_autocmd("FileType", { pattern = {...}, callback = fn })
- Example (from file):
  ```lua
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("filetype_indent", { clear = true }),
    pattern = { "python", "rust" },
    callback = function()
      vim.opt_local.shiftwidth = 4
      vim.opt_local.tabstop = 4
      vim.opt_local.softtabstop = 4
    end,
  })
  ```

**New Plugin with Custom Config:**
- Location: `lua/plugins/[feature].lua`
- Pattern: Use config function (not just opts) for complex logic
- Example (from `lua/plugins/linting.lua` lsp.lua):
  ```lua
  return {
    {
      "plugin/name",
      opts = { ... },  -- or omit if config function only
      config = function(_, opts)
        -- Custom initialization logic here
        -- opts passed in if specified above
      end,
    },
  }
  ```

**New Buffer-Scoped Keymap (for LSP or plugin):**
- Location: Inside plugin config function or LspAttach autocmd
- Pattern: vim.keymap.set(mode, key, action, { buffer = bufnr, desc = "..." })
- Example (from `lua/plugins/lsp.lua` LspAttach autocmd):
  ```lua
  map("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
  -- where map function is defined as:
  local map = function(keys, func, desc, mode)
    mode = mode or "n"
    vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
  end
  ```

**New LSP Server Configuration:**
- Location: `lua/plugins/lsp.lua` inside config function, BEFORE require("mason-lspconfig").setup()
- Pattern: vim.lsp.config(server_name, { settings = {...} })
- Placement: Must run before mason-lspconfig.setup() so automatic_enable picks up custom settings
- Example (from file for lua_ls):
  ```lua
  vim.lsp.config("lua_ls", {
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        workspace = {
          checkThirdParty = false,
          library = { vim.env.VIMRUNTIME },
        },
      },
    },
  })
  ```

**New Formatter:**
- Location: `lua/plugins/formatting.lua` in formatters_by_ft table
- Pattern: filetype = { "formatter_name" } (can chain multiple)
- Example: `python = { "ruff_fix", "ruff_format", "ruff_organize_imports" }`
- Tool installation: Add binary name to `lua/plugins/linting.lua` mason-tool-installer ensure_installed list

**New Linter:**
- Location: `lua/plugins/linting.lua`
  1. Add binary to mason-tool-installer ensure_installed list
  2. Add filetype mapping in nvim-lint linters_by_ft table
- Example: `json = { "jsonlint" }`

**New Treesitter Parser:**
- Location: `lua/plugins/treesitter.lua` in ensure_installed list
- Pattern: Add parser name (e.g., "go", "rust", "javascript")
- Compile: `:TSUpdate` manually or auto on first load (sync_install=false)

**New Which-Key Group Label:**
- Location: `lua/plugins/qol.lua` in which-key spec
- Pattern: `{ "<leader>prefix", group = "Group Label" }`
- Example (from file): `{ "<leader>b", group = "Buffer" }`

## Special Directories

**`lua/plugins/` (Auto-Discovered by lazy.nvim):**
- Purpose: Feature plugins loaded on-demand
- Generated: No (manually created)
- Committed: Yes (all plugin specs in version control)
- How they load: lazy.nvim reads `{ import = "plugins" }` in init.lua and auto-requires all *.lua files
- Deduplication: lazy.nvim automatically deduplicates if same plugin listed in multiple specs

**`lua/config/` (Synchronous Core Configuration):**
- Purpose: Load before plugin manager (options, keymaps, autocmds)
- Generated: No (manually created)
- Committed: Yes (core config in version control)
- How they load: Explicitly required in init.lua before lazy.nvim bootstrap
- Execution timing: Synchronous (blocks startup until complete)

**`.config/nvim` (Neovim Config Directory):**
- Purpose: Standard Neovim config location on Linux/macOS
- Generated: No
- Committed: Yes (symlinked or cloned from version control)
- Standard path: `~/.config/nvim` (used by Neovim on Linux/macOS) or `~/AppData/Local/nvim` (Windows)

**`lazy-lock.json`:**
- Purpose: Lock file: pins plugin versions and git commits for reproducibility
- Generated: Yes (auto-generated by lazy.nvim on first plugin install/update)
- Committed: Yes (should be committed to version control)
- Update: Run `:Lazy` in Neovim to sync and regenerate

## Notes on Lazy.nvim Structure

**Plugin Auto-Discovery:**
- init.lua calls `lazy.setup({ spec = { import = "plugins" } })`
- lazy.nvim walks `lua/plugins/` directory and requires each *.lua file
- Each file should return a plugin spec table or array of tables
- Order of processing: alphabetical by filename (but lazy.nvim handles dependency ordering)

**Lazy-Loading Events:**
- BufReadPost: General file read (used by gitsigns, nvim-lint, treesitter indirectly)
- InsertEnter: Before entering insert mode (used by autopairs)
- VeryLazy: After UI finishes initializing (used by which-key, indent-blankline)
- CursorHold: After cursor pauses (used by diagnostic float in lsp.lua)
- LspAttach: When LSP server attaches (used by fidget.nvim)
- Custom keys: Keymaps that trigger plugin load (used by conform, trouble, neo-tree, toggleterm)

**Dependency Semantics:**
- dependencies = {...} in a plugin spec: lazy.nvim loads those plugins first
- Used for: blink.cmp dependency of mason-lspconfig (LSP capabilities patching), nvim-navic dependency of lualine (winbar ordering)
- Deduplication: If same plugin listed as dependency in multiple specs, lazy.nvim installs once

---

*Structure analysis: 2026-03-03*
