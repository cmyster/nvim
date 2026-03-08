# Technology Stack

**Analysis Date:** 2026-03-08

## Languages

**Primary:**
- Lua (LuaJIT) - All configuration files, plugin specs, and custom modules

**Secondary:**
- Vim script - Minimal; only used implicitly via `vim.cmd` calls (e.g., colorscheme application, whitespace stripping regex)

## Runtime

**Environment:**
- Neovim 0.11+ (required: uses `vim.hl.on_yank`, `vim.lsp.config()`, `vim.uv`, mason-lspconfig v2 `automatic_enable` API)
- LuaJIT (embedded in Neovim; confirmed in `.luacheckrc` `std = "luajit"`)

**Package Manager:**
- lazy.nvim (plugin manager, bootstrapped from git in `init.lua`)
- Lockfile: `lazy-lock.json` (present, tracked in git then removed via `.gitignore`)

## Frameworks

**Core:**
- lazy.nvim - Plugin management, lazy-loading, dependency resolution
- nvim-lspconfig - LSP client configuration
- mason.nvim - External tool installer (LSP servers, formatters, linters)
- mason-lspconfig.nvim - Bridges mason.nvim and nvim-lspconfig with `automatic_enable`
- mason-tool-installer.nvim - Auto-installs formatters and linters on first launch

**Completion:**
- blink.cmp 1.x - Completion engine with native Rust fuzzy matching (pre-built binaries)
- lazydev.nvim - Neovim Lua API completions for `vim.*` globals
- friendly-snippets - VSCode-compatible snippet library (40+ languages)

**Syntax/Parsing:**
- nvim-treesitter (branch: master) - Syntax highlighting, indentation, incremental selection
- nvim-treesitter-textobjects (branch: master) - Structural text objects (`af`, `if`, `ac`, `ic`, `aa`, `ia`)

**Formatting:**
- conform.nvim v9 - Format-on-save and manual formatting

**Linting:**
- nvim-lint - Async per-filetype linting alongside LSP diagnostics

**Testing:**
- Not applicable (this is an editor configuration, not a software project with tests)

**Build/Dev:**
- No build system; configuration is loaded directly by Neovim at startup

## Key Dependencies

**Critical (UI/UX):**
- `folke/tokyonight.nvim` - Colorscheme (tokyonight-night variant, priority 1000)
- `nvim-lualine/lualine.nvim` - Statusline with git, LSP, and navic breadcrumb integration
- `SmiteshP/nvim-navic` - LSP-backed winbar breadcrumbs (function/class context)
- `nvim-neo-tree/neo-tree.nvim` (branch: v3.x) - File tree with git status and buffers panel
- `folke/which-key.nvim` v3 - Keymap discoverability popup

**Critical (Editor Features):**
- `lewis6991/gitsigns.nvim` v2 - Gutter diff signs, inline blame toggle
- `tpope/vim-fugitive` - Git command interface (`:Git`)
- `folke/trouble.nvim` v3 - Navigable diagnostics panel
- `j-hui/fidget.nvim` v1.6.1 - LSP progress spinner
- `akinsho/toggleterm.nvim` - Toggleable terminal panel

**Quality of Life:**
- `lukas-reineke/indent-blankline.nvim` v3 - Indent guides with treesitter scope
- `windwp/nvim-autopairs` - Auto-close brackets/quotes (treesitter-aware)
- `b0o/SchemaStore.nvim` - JSON/YAML schema catalogue for yamlls and jsonls

**Infrastructure (shared dependencies):**
- `nvim-tree/nvim-web-devicons` - Icon provider (lazy-loaded)
- `nvim-lua/plenary.nvim` - Lua utility library (lazy-loaded)
- `MunifTanjim/nui.nvim` - UI component library for neo-tree (lazy-loaded)

## LSP Servers (installed via Mason)

| Server | Language | Custom Config |
|---|---|---|
| `clangd` | C/C++ | Default |
| `pyright` | Python | Default |
| `lua_ls` | Lua | Custom: LuaJIT runtime, VIMRUNTIME library injection |
| `bashls` | Bash | Default |
| `yamlls` | YAML | Custom: SchemaStore.nvim integration |
| `dockerls` | Dockerfile | Default |
| `terraformls` | Terraform | Default |
| `jsonls` | JSON | Custom: SchemaStore.nvim integration, validation enabled |
| `rust_analyzer` | Rust | Default (note: may conflict with rustup-installed instance) |

## Formatters (installed via Mason or system)

| Formatter | Filetypes | Installed Via |
|---|---|---|
| `clang-format` | c, cpp | Mason |
| `ruff` (fix + format + organize_imports) | python | Mason |
| `stylua` | lua | Mason |
| `shfmt` | sh, bash | Mason |
| `prettier` | yaml, json | Mason |
| `terraform_fmt` | terraform | System (terraform binary) |
| `rustfmt` | rust | System (rustup, NOT Mason) |

## Linters (installed via Mason)

| Linter | Filetypes | Installed Via |
|---|---|---|
| `cpplint` | c, cpp | Mason |
| `ruff` | python | Mason (same binary as formatter) |
| `luacheck` | lua | Mason (reads `.luacheckrc`) |
| `shellcheck` | sh, bash | Mason |
| `yamllint` | yaml | Mason |
| `hadolint` | dockerfile | Mason |
| `tflint` | terraform | Mason |
| `jsonlint` | json | Mason |

## Treesitter Parsers

Explicitly installed via `ensure_installed`: `c`, `cpp`, `python`, `lua`, `bash`, `yaml`, `hcl`, `json`, `rust`, `dockerfile`, `cmake`, `make`

## Configuration

**Environment:**
- No `.env` files; no environment variables required
- All configuration is declarative Lua in `lua/config/` and `lua/plugins/`
- Mason manages tool installation to Neovim's `stdpath("data")/mason/`

**Static Analysis:**
- `.luacheckrc` - Luacheck config: declares `vim` as global, uses `luajit` std, disables line length warnings

**Git:**
- `.gitignore` - Excludes `lazy-lock.json`

## Platform Requirements

**Development:**
- Neovim >= 0.11 (required for `vim.hl.on_yank`, `vim.lsp.config()`, mason-lspconfig v2 API)
- Git (for lazy.nvim bootstrap and gitsigns/fugitive)
- A Nerd Font (mono variant) for devicons and lualine separators
- Terminal with true color support (`termguicolors = true`)
- System clipboard provider (for `clipboard = "unnamedplus"`)

**External Tool Requirements:**
- Rust toolchain via rustup (provides `rust-analyzer` and `rustfmt` outside Mason)
- Terraform binary on PATH (provides `terraform fmt`)
- All other tools installed automatically by Mason on first launch

**Host OS:**
- Linux (Gentoo) - current deployment target
- No OS-specific code; should work on any Neovim 0.11+ platform

---

*Stack analysis: 2026-03-08*
