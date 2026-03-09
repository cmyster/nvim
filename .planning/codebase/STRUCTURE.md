# Codebase Structure

**Analysis Date:** 2026-03-09

## Directory Layout

```
nvim/
├── init.lua                    # Entry point: leader key, config requires, lazy.nvim bootstrap
├── lazy-lock.json              # Plugin version lockfile (gitignored)
├── .luacheckrc                 # Luacheck config: vim global, LuaJIT std, no line length limit
├── .gitignore                  # Ignores lazy-lock.json
├── lua/
│   ├── config/                 # Core editor configuration (no plugins)
│   │   ├── options.lua         # vim.opt settings (numbers, indent, search, splits, colors)
│   │   ├── keymaps.lua         # Non-plugin keybindings (window nav, buffer mgmt, terminal escape)
│   │   ├── autocmds.lua        # Global autocommands (yank highlight, cursor restore, whitespace strip, filetype indent)
│   │   └── helpscreen.lua      # Startup help overlay module (floating window with keybinding reference)
│   └── plugins/                # lazy.nvim plugin specs (auto-discovered)
│       ├── colorscheme.lua     # tokyonight-night theme (eager, priority 1000)
│       ├── completion.lua      # blink.cmp + lazydev + friendly-snippets
│       ├── deps.lua            # Shared dependencies (nvim-web-devicons, plenary, nui)
│       ├── diagnostics.lua     # trouble.nvim v3 + fidget.nvim (LSP progress)
│       ├── filetree.lua        # neo-tree.nvim v3 (file tree + buffers panel)
│       ├── formatting.lua      # conform.nvim (format-on-save + manual <leader>f)
│       ├── git.lua             # gitsigns.nvim + vim-fugitive
│       ├── linting.lua         # mason-tool-installer + nvim-lint
│       ├── lsp.lua             # mason + mason-lspconfig + nvim-lspconfig + SchemaStore
│       ├── qol.lua             # which-key, indent-blankline, nvim-autopairs
│       ├── statusline.lua      # lualine.nvim + nvim-navic (winbar breadcrumbs)
│       ├── terminal.lua        # toggleterm.nvim (horizontal terminal)
│       └── treesitter.lua      # nvim-treesitter + textobjects
└── .planning/
    └── codebase/               # Architecture analysis documents
```

## Directory Purposes

**`lua/config/`:**
- Purpose: Core editor settings independent of any plugin
- Contains: Plain Lua scripts that run side-effects on `require()`; one module (`helpscreen.lua`) returns a table
- Key files: `options.lua` (must load before plugins for `termguicolors`), `keymaps.lua` (non-plugin maps)

**`lua/plugins/`:**
- Purpose: All plugin declarations and configuration, one file per logical concern
- Contains: Lua files each returning a lazy.nvim spec table (or list of tables)
- Key files: `lsp.lua` (largest and most complex: diagnostic config, LspAttach autocmd, 4 plugin specs), `completion.lua` (blink.cmp with source configuration)

**`.planning/`:**
- Purpose: Project analysis and planning documents
- Contains: Codebase mapping documents
- Generated: Yes (by analysis tooling)
- Committed: Yes

## Key File Locations

**Entry Points:**
- `init.lua`: Neovim startup entry point; loads config modules, bootstraps lazy.nvim

**Configuration:**
- `lua/config/options.lua`: All vim.opt settings (indentation, search, splits, colors)
- `lua/config/keymaps.lua`: Global keybindings not tied to a specific plugin
- `lua/config/autocmds.lua`: Global autocommands (yank highlight, cursor restore, whitespace strip, filetype-specific indent)
- `.luacheckrc`: Luacheck static analyzer config (vim global declaration, LuaJIT std)

**LSP & Tooling:**
- `lua/plugins/lsp.lua`: LSP server list (`ensure_installed`), per-server `vim.lsp.config()` overrides, diagnostic config, LspAttach keymaps
- `lua/plugins/linting.lua`: Tool binary install list (`ensure_installed` in mason-tool-installer), linter-to-filetype mapping
- `lua/plugins/formatting.lua`: Formatter-to-filetype mapping, format-on-save config

**UI:**
- `lua/plugins/colorscheme.lua`: Theme selection (tokyonight-night)
- `lua/plugins/statusline.lua`: Statusline layout, winbar breadcrumbs, gitsigns diff integration
- `lua/plugins/filetree.lua`: File explorer configuration
- `lua/config/helpscreen.lua`: Custom floating help window

**Completion:**
- `lua/plugins/completion.lua`: Completion engine config, source priority, keymap preset

## Naming Conventions

**Files:**
- `lua/config/*.lua`: Lowercase descriptive name matching the concern (`options`, `keymaps`, `autocmds`, `helpscreen`)
- `lua/plugins/*.lua`: Lowercase name matching the plugin's primary function, not the plugin name (`lsp` not `mason-lspconfig`, `formatting` not `conform`, `filetree` not `neo-tree`)

**Directories:**
- `lua/config/`: Editor configuration modules
- `lua/plugins/`: Plugin specification files (lazy.nvim convention)

**Augroups:**
- Config-level: descriptive snake_case (`highlight_yank`, `restore_cursor`, `strip_whitespace`, `json_conceal`, `filetype_indent`, `helpscreen_startup`)
- Plugin-level: `project-` prefix with kebab-case (`project-lsp-attach`, `project-lint`, `project-diag-float`)

## Where to Add New Code

**New Plugin:**
- Create `lua/plugins/{concern}.lua` (name after what it does, not the plugin name)
- Return a lazy.nvim spec table or list of tables
- Use `opts` style unless imperative `config` function is required
- Add lazy-loading triggers (`event`, `cmd`, `keys`, or `ft`) unless the plugin must load eagerly
- If the plugin provides formatter/linter binaries, add them to `ensure_installed` in `lua/plugins/linting.lua`
- If the plugin is an LSP server, add to `ensure_installed` in `lua/plugins/lsp.lua`

**New Keymap (non-plugin):**
- Add to `lua/config/keymaps.lua` using `vim.keymap.set()` with a `desc` string
- Update the help screen lines in `lua/config/helpscreen.lua` `build_lines()` function
- Follow existing `<leader>` prefix grouping (b=buffer, f=format, g=git, x=diagnostics, t=terminal, e=explorer, h=help)

**New Autocommand:**
- Add to `lua/config/autocmds.lua` for global autocommands
- Always create a named augroup with `clear = true`
- Use `vim.api.nvim_create_autocmd()` (not legacy `vim.cmd("autocmd ...")`)

**New Editor Option:**
- Add to `lua/config/options.lua` under the relevant comment section
- Use `opt.{setting}` pattern (local alias for `vim.opt`)

**New LSP Server:**
1. Add server name to `ensure_installed` in `lua/plugins/lsp.lua`
2. If custom settings needed: add `vim.lsp.config("server_name", { settings = { ... } })` in the `config` function before `require("mason-lspconfig").setup(opts)`
3. Add formatter to `formatters_by_ft` in `lua/plugins/formatting.lua` if applicable
4. Add linter to `linters_by_ft` in `lua/plugins/linting.lua` if applicable
5. Add formatter/linter binary to `ensure_installed` in `lua/plugins/linting.lua` (mason-tool-installer)

**New Filetype Support:**
1. Add treesitter parser to `ensure_installed` in `lua/plugins/treesitter.lua`
2. Add LSP server (see above)
3. Add formatter mapping in `lua/plugins/formatting.lua` `formatters_by_ft`
4. Add linter mapping in `lua/plugins/linting.lua` `linters_by_ft`
5. Add tool binaries to `ensure_installed` in `lua/plugins/linting.lua`
6. If custom indentation needed: add filetype pattern to the `filetype_indent` autocmd in `lua/config/autocmds.lua`

**Shared Dependencies:**
- Add to `lua/plugins/deps.lua` with `lazy = true` if multiple plugins need the same dependency

## Special Directories

**`lua/plugins/`:**
- Purpose: Auto-discovered by lazy.nvim via `{ import = "plugins" }` in `init.lua`
- Generated: No (manually authored)
- Committed: Yes
- Note: Every `.lua` file in this directory is loaded as a plugin spec; do not place non-spec files here

**`.planning/`:**
- Purpose: Codebase analysis and project planning
- Generated: Yes
- Committed: Yes

---

*Structure analysis: 2026-03-09*
