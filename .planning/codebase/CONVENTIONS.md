# Coding Conventions

**Analysis Date:** 2026-03-03

## Naming Patterns

**Files:**
- Lowercase with hyphens for multi-word names: `mason-lspconfig`, `nvim-lspconfig`
- Plugin files: all lowercase, single word or hyphenated: `lsp.lua`, `qol.lua`, `git.lua`
- Config module files: lowercase descriptive names: `options.lua`, `keymaps.lua`, `autocmds.lua`
- Abbreviations used where conventional: `lsp`, `qol`, `linting` (not spell out)

**Functions:**
- camelCase for local functions: `diff_source()` in `lua/plugins/statusline.lua`
- snake_case for callbacks and handlers: `on_attach`, `callback`, `config` (Lua convention)
- Descriptive names for anonymous functions passed to require/setup: `function()` preferred over abbreviations

**Variables:**
- snake_case throughout: `max_line_length`, `gitsigns_status_dict`, `virtual_text_pos`
- Local cache variables: `local opt`, `local map`, `local gs`, `local lint` (single-letter for brevity when scope is clear)
- Config option names: preserve exact names from plugins (e.g., `lsp_format` not `lsp_fmt`)

**Types:**
- Lua tables use UPPERCASE for constants and configuration tables
- Comments indicate table structure in complex cases (see `lua/plugins/statusline.lua` with `diff_source` function)

## Code Style

**Formatting:**
- Indentation: 2 spaces globally (set in `lua/config/options.lua` via `opt.shiftwidth = 2`)
- Per-language overrides: 4 spaces for Python and Rust (enforced in `lua/config/autocmds.lua` via FileType autocommand)
- Tab conversion: `opt.expandtab = true` — always use spaces, never tabs
- Line length: 80 character color column set in `lua/config/options.lua` (`opt.colorcolumn = "80"`)

**Linting:**
- Tool: luacheck (static analyzer)
- Config file: `.luacheckrc` at repository root
- Global suppression: `vim` declared as known global in `.luacheckrc` to avoid "undefined global vim" warnings in Neovim config files
- Standard: LuaJIT (Neovim embeds LuaJIT, not standard Lua 5.x) — configured in `.luacheckrc` as `std = "luajit"`
- Line length warnings: disabled in `.luacheckrc` (`max_line_length = false`) because stylua handles formatting independently

## Import Organization

**Order:**
1. Standard Lua functions and vim global (implicit in all files)
2. Local variable assignments (e.g., `local opt = vim.opt`, `local map = vim.keymap.set`)
3. Function definitions (if any)
4. Return statement with plugin specs

**Path Aliases:**
- No path aliases used — all imports use `require()` with relative module paths
- Module structure: `require("config.options")`, `require("plugins")` (auto-discovered via `{ import = "plugins" }` in `init.lua`)

**Pattern in init.lua:**
```lua
-- MUST be first: mapleader before lazy bootstrap
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Load config modules before lazy.setup()
require("config.options")
require("config.keymaps")
require("config.autocmds")

-- Bootstrap lazy.nvim
-- ... setup code ...

-- Initialize lazy with auto-discovery
require("lazy").setup({
  spec = { { import = "plugins" } },
  -- ... options ...
})
```

## Error Handling

**Patterns:**
- `pcall()` for risky Neovim API calls that might fail: `pcall(vim.api.nvim_win_set_cursor, 0, mark)` in `lua/config/autocmds.lua`
- Conditional checks before operations: `if mark[1] > 0 and mark[1] <= lcount then` (restore cursor only if valid)
- Git command output validation: check `vim.v.shell_error ~= 0` after `vim.fn.system()` calls (see `init.lua` lazy bootstrap section)
- Graceful exit: `os.exit(1)` after user notification via `vim.api.nvim_echo()` with `WarningMsg` highlight
- No explicit error throwing — relies on Neovim's built-in error propagation

## Logging

**Framework:** vim.notify (Neovim built-in) with fallback to `vim.api.nvim_echo()`

**Patterns:**
- User-facing messages use `vim.api.nvim_echo()` with message arrays and highlights: `{ "message", "HighlightGroup" }`
- Example in `init.lua`:
  ```lua
  vim.api.nvim_echo({
    { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
    { out,                            "WarningMsg" },
    { "\nPress any key to exit...",   "" },
  }, true, {})
  ```
- Highlights used: `"ErrorMsg"`, `"WarningMsg"` (built-in Neovim highlight groups)
- Second parameter `true` = echo in all windows; `{}` = no opts

## Comments

**When to Comment:**
- File-level header comment: always present with purpose and any critical API notes
  - Example: `-- lua/plugins/lsp.lua` followed by high-level description and API notes
- Section dividers: markdown-style separator lines with section titles
  - Pattern: `-- ---------------------------------------------------------------------------`
  - Used to organize large files into logical phases or concerns
- Inline comments: explain WHY, not WHAT — code should be self-documenting
  - Good: `-- CRITICAL: blink.cmp must patch capabilities before any server starts`
  - Avoid: `-- assign to variable` (obvious from code)
- Complex configuration blocks: comment the purpose and any pitfalls
  - Example in `lsp.lua`: detailed notes on why SchemaStore integration requires disabling built-in schemaStore

**JSDoc/TSDoc:**
- Not used — Lua's comment syntax is sufficient
- Type annotations: use inline Lua type comments where helpful (e.g., `---@module "ibl"` before opts table in `qol.lua`)
- Neovim diagnostic annotations: `---@module` used to guide LSP completion for plugin configs

## Function Design

**Size:** Functions should fit single logical concern
- Autocmd callbacks: 5-20 lines typical
- Config setup functions: 30-50 lines acceptable
- Helper functions like `diff_source()` in `statusline.lua`: 10-15 lines

**Parameters:**
- Most functions are callbacks passed to vim API — use function() anonymous form
- Named parameters for setup/opts tables only
- Example: `require("conform").format({ async = true })` (named table parameter)

**Return Values:**
- Plugin specs: return single table or array of tables
  - Single plugin: `return { { "plugin/name", ... } }`
  - Multiple plugins: `return { { "plugin1", ... }, { "plugin2", ... } }`
- Autocmd callbacks: typically no return value (void)
- Helper functions: return computed values (e.g., `diff_source()` returns table with added/modified/removed fields)

## Module Design

**Exports:**
- Plugin files: always return a table (single spec or array of specs)
- Config files: execute directly (no return statement), affect global state via vim.* API
- No named exports — Lua doesn't support module.exports; use return table or side effects

**Barrel Files:**
- Not used — each plugin file is self-contained
- Plugin discovery: done by lazy.nvim `{ import = "plugins" }` which auto-loads all `lua/plugins/*.lua` files

**File Organization:**
```
init.lua                              # Entry point, mapleader, require config modules, bootstrap lazy
lua/
├── config/
│   ├── options.lua                  # vim.opt settings
│   ├── keymaps.lua                  # global keymaps (vim.keymap.set)
│   └── autocmds.lua                 # global autocommands
└── plugins/                         # Plugin specs (auto-discovered by lazy.nvim)
    ├── lsp.lua                      # LSP + mason-lspconfig + nvim-lspconfig
    ├── completion.lua               # blink.cmp + lazydev + snippets
    ├── formatting.lua               # conform.nvim
    ├── linting.lua                  # nvim-lint + mason-tool-installer
    ├── git.lua                      # gitsigns.nvim + vim-fugitive
    ├── diagnostics.lua              # trouble.nvim + fidget.nvim
    ├── treesitter.lua               # nvim-treesitter + textobjects
    ├── qol.lua                      # which-key + indent-blankline + autopairs
    ├── statusline.lua               # lualine.nvim + nvim-navic
    ├── filetree.lua                 # neo-tree.nvim
    ├── terminal.lua                 # toggleterm.nvim
    ├── colorscheme.lua              # tokyonight.nvim
    └── deps.lua                     # Dependency declarations (devicons, plenary, nui)
```

## Plugin Configuration Pattern

**Consistent approach across all plugin files:**

1. **File header:** File path + description + critical API notes
2. **Immediate setup code:** Autocmds and vim.diagnostic.config() that must run at load time (before return)
3. **Return statement:** Array of plugin specs

**Plugin spec structure (opts style preferred):**
```lua
return {
  {
    "plugin/name",
    -- Lazy loading strategy
    event = "BufReadPost",  -- or: lazy = false, cmd = "Command", keys = {...}, ft = "filetype"
    -- Dependencies (load order)
    dependencies = { "other/plugin" },
    -- Configuration (opts style preferred over config function)
    opts = {
      -- Plain table — lazy.nvim merges with other plugins' opts via opts_extend
      setting = value,
    },
    -- OR config function (when opts alone insufficient):
    config = function(_, opts)
      -- Setup code using opts
      require("module").setup(opts)
    end,
  },
}
```

**Exception:** nvim-lint uses `config` function because linters_by_ft assignment and autocmd creation require imperative code (cannot be expressed as opts table).

## Keymap Patterns

**Global keymaps (in `config/keymaps.lua`):**
- Use `vim.keymap.set()` with descriptive `desc` attribute
- Window navigation: Ctrl+hjkl standard
- Buffer management: `<leader>b` prefix with `d`/`n`/`p` suffixes (delete/next/previous)
- Format: `<leader>f` maps to `conform.format()`
- Git: `<leader>g` prefix (branch display via statusline, blame toggle via gitsigns)
- Diagnostics: `<leader>x` prefix
- File tree: `<leader>e` and `\` both toggle

**Buffer-scoped keymaps (in LSP and plugin config):**
- Set in autocmd callbacks with `buffer = event.buf` or `buffer = bufnr`
- LSP keymaps defined in `LspAttach` autocmd in `lsp.lua`
- Example: `map("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")`
  - Uses bracketed uppercase letters in desc for key hints (LSP standard)

## Indentation Overrides

**Default:** 2 spaces (set in `options.lua`)

**Exceptions (per FileType autocommand in `autocmds.lua`):**
- Python: 4 spaces
- Rust: 4 spaces
- All other types: 2 spaces

These are enforced via `vim.opt_local` in the FileType autocommand callback, allowing per-buffer overrides without global changes.
