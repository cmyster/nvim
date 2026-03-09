# Technology Stack

**Analysis Date:** 2026-03-09

## Languages

**Primary:**
- Lua (LuaJIT) - All configuration files (`init.lua`, `lua/**/*.lua`)

**Secondary:**
- Rust (compile-time only) - blink.cmp uses pre-built Rust fuzzy matcher binary; no Rust toolchain required at config level
- VimL - Minimal usage; only via `vim.cmd` calls (e.g., colorscheme command in `lua/plugins/colorscheme.lua`)

## Runtime

**Environment:**
- Neovim 0.11+ (required: uses `vim.lsp.config()` API, `vim.hl.on_yank()`, `vim.uv`)
- LuaJIT embedded runtime (set in `.luacheckrc` as `std = "luajit"`)

**Package Manager:**
- lazy.nvim (plugin manager) - bootstrapped from git in `init.lua`
- Lockfile: `lazy-lock.json` (present, gitignored)

## Frameworks

**Core:**
- lazy.nvim - Plugin management, lazy-loading, dependency resolution (`init.lua` lines 12-41)
- nvim-lspconfig - LSP client configuration (`lua/plugins/lsp.lua`)
- mason.nvim - External tool installer for LSP servers, formatters, linters (`lua/plugins/lsp.lua`, `lua/plugins/linting.lua`)

**Completion:**
- blink.cmp v1.* - Completion engine with native Rust fuzzy matching (`lua/plugins/completion.lua`)
- friendly-snippets - VSCode-compatible snippet library (`lua/plugins/completion.lua`)

**Syntax:**
- nvim-treesitter (master branch) - Syntax highlighting, indentation, incremental selection (`lua/plugins/treesitter.lua`)
- nvim-treesitter-textobjects (master branch) - Structural text objects (`lua/plugins/treesitter.lua`)

**Formatting:**
- conform.nvim v9 - Format-on-save and manual formatting (`lua/plugins/formatting.lua`)

**Linting:**
- nvim-lint - Async linting with diagnostics (`lua/plugins/linting.lua`)

**Build/Dev:**
- mason-tool-installer - Auto-installs formatter and linter binaries (`lua/plugins/linting.lua`)
- mason-lspconfig v2 - Manages LSP server installation and automatic enable (`lua/plugins/lsp.lua`)

## Key Dependencies

**Critical (29 plugins total per lazy-lock.json):**

| Plugin | Purpose | Config File |
|--------|---------|-------------|
| `saghen/blink.cmp` | Completion engine | `lua/plugins/completion.lua` |
| `neovim/nvim-lspconfig` | LSP configuration | `lua/plugins/lsp.lua` |
| `mason-org/mason.nvim` | Tool installer | `lua/plugins/lsp.lua` |
| `mason-org/mason-lspconfig.nvim` | LSP server management | `lua/plugins/lsp.lua` |
| `stevearc/conform.nvim` | Formatting | `lua/plugins/formatting.lua` |
| `mfussenegger/nvim-lint` | Linting | `lua/plugins/linting.lua` |
| `nvim-treesitter/nvim-treesitter` | Syntax/highlighting | `lua/plugins/treesitter.lua` |
| `folke/tokyonight.nvim` | Colorscheme | `lua/plugins/colorscheme.lua` |

**UI/UX:**
| Plugin | Purpose | Config File |
|--------|---------|-------------|
| `nvim-neo-tree/neo-tree.nvim` (v3.x) | File tree | `lua/plugins/filetree.lua` |
| `nvim-lualine/lualine.nvim` | Statusline + winbar | `lua/plugins/statusline.lua` |
| `SmiteshP/nvim-navic` | LSP breadcrumbs in winbar | `lua/plugins/statusline.lua` |
| `folke/trouble.nvim` v3 | Diagnostics panel | `lua/plugins/diagnostics.lua` |
| `j-hui/fidget.nvim` v1.6.1 | LSP progress spinner | `lua/plugins/diagnostics.lua` |
| `folke/which-key.nvim` v3 | Keymap popup | `lua/plugins/qol.lua` |
| `lukas-reineke/indent-blankline.nvim` v3 | Indent guides | `lua/plugins/qol.lua` |
| `windwp/nvim-autopairs` | Auto-close brackets | `lua/plugins/qol.lua` |
| `akinsho/toggleterm.nvim` | Terminal integration | `lua/plugins/terminal.lua` |

**Git:**
| Plugin | Purpose | Config File |
|--------|---------|-------------|
| `lewis6991/gitsigns.nvim` v2 | Gutter signs + blame | `lua/plugins/git.lua` |
| `tpope/vim-fugitive` | Git commands | `lua/plugins/git.lua` |

**Library/Utility (lazy-loaded on demand):**
| Plugin | Purpose | Config File |
|--------|---------|-------------|
| `nvim-lua/plenary.nvim` | Lua utility library | `lua/plugins/deps.lua` |
| `MunifTanjim/nui.nvim` | UI component library | `lua/plugins/deps.lua` |
| `nvim-tree/nvim-web-devicons` | File type icons | `lua/plugins/deps.lua` |
| `b0o/SchemaStore.nvim` | JSON/YAML schema catalog | `lua/plugins/lsp.lua` |
| `folke/lazydev.nvim` | Neovim Lua API completions | `lua/plugins/completion.lua` |
| `rafamadriz/friendly-snippets` | Snippet library | `lua/plugins/completion.lua` |

## LSP Servers (managed by Mason)

Configured in `lua/plugins/lsp.lua` via `ensure_installed`:
- `clangd` - C/C++
- `pyright` - Python
- `lua_ls` - Lua (with Neovim runtime library injected)
- `bashls` - Bash
- `yamlls` - YAML (SchemaStore integration)
- `dockerls` - Dockerfile
- `terraformls` - Terraform
- `jsonls` - JSON (SchemaStore integration)
- `rust_analyzer` - Rust

## Formatters (managed by mason-tool-installer)

Configured in `lua/plugins/linting.lua` and used by `lua/plugins/formatting.lua`:
- `clang-format` - C/C++
- `ruff` - Python (fix + format + organize imports)
- `stylua` - Lua
- `shfmt` - Bash/sh
- `prettier` - YAML, JSON
- `rustfmt` - Rust (managed by rustup, NOT Mason)
- `terraform_fmt` - Terraform (uses terraform binary)

## Linters (managed by mason-tool-installer)

Configured in `lua/plugins/linting.lua`:
- `cpplint` - C/C++
- `ruff` - Python (same binary as formatter)
- `luacheck` - Lua (reads `.luacheckrc`)
- `shellcheck` - Bash/sh
- `yamllint` - YAML
- `hadolint` - Dockerfile
- `tflint` - Terraform
- `jsonlint` - JSON

## Configuration

**Neovim Options:**
- `lua/config/options.lua` - Editor settings (line numbers, indentation, search, splits, clipboard)
- Default indentation: 2 spaces (overridden to 4 for Python and Rust via `lua/config/autocmds.lua`)

**Linting Config:**
- `.luacheckrc` - Luacheck globals (`vim`), std set to `luajit`, no line length limit

**Git:**
- `.gitignore` - Ignores `lazy-lock.json`

**Plugin Auto-Discovery:**
- lazy.nvim auto-imports all files in `lua/plugins/` directory (`init.lua` line 35)

## Platform Requirements

**Development:**
- Neovim >= 0.11 (hard requirement for `vim.lsp.config()` API)
- Git (for lazy.nvim bootstrap and gitsigns/fugitive)
- Nerd Font (mono variant) for devicons and UI elements
- C compiler (for treesitter parser compilation via `:TSUpdate`)

**External Tools (auto-installed by Mason):**
- All LSP servers, formatters, and linters listed above
- Exception: `rustfmt` requires Rust toolchain via rustup
- Exception: `terraform fmt` requires terraform binary (bundled with terraformls)

---

*Stack analysis: 2026-03-09*
