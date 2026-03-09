# External Integrations

**Analysis Date:** 2026-03-09

## Overview

This is a Neovim configuration repository. It has no application-level external service integrations (no APIs, databases, or auth providers). All "integrations" are between Neovim and development tooling installed on the local machine.

## Tool Management: Mason

**Mason** is the central tool installer that downloads and manages external binaries.

**Mason Core:**
- Plugin: `mason.nvim` (`lua/plugins/lsp.lua`)
- Storage: `~/.local/share/nvim/mason/` (Neovim stdpath "data")
- Binaries added to Neovim's PATH automatically

**Mason-managed LSP Servers** (via `mason-lspconfig.nvim` in `lua/plugins/lsp.lua`):
- `clangd`, `pyright`, `lua_ls`, `bashls`, `yamlls`, `dockerls`, `terraformls`, `jsonls`, `rust_analyzer`

**Mason-managed Formatters and Linters** (via `mason-tool-installer.nvim` in `lua/plugins/linting.lua`):
- Formatters: `clang-format`, `ruff`, `stylua`, `shfmt`, `prettier`
- Linters: `cpplint`, `luacheck`, `shellcheck`, `yamllint`, `hadolint`, `tflint`, `jsonlint`

## Schema Integrations

**SchemaStore.nvim** (`lua/plugins/lsp.lua`):
- Provides JSON and YAML schema catalogs to `jsonls` and `yamlls` LSP servers
- JSON schemas: `require("schemastore").json.schemas()` passed to `jsonls` settings
- YAML schemas: `require("schemastore").yaml.schemas()` passed to `yamlls` settings
- Built-in schemaStore explicitly disabled on `yamlls` to prevent conflict

## Git Integration

**gitsigns.nvim** (`lua/plugins/git.lua`):
- Reads git diff data from the local `.git` directory
- Provides buffer-local sign column indicators and inline blame
- Exposes `vim.b.gitsigns_status_dict` consumed by lualine diff component in `lua/plugins/statusline.lua`

**vim-fugitive** (`lua/plugins/git.lua`):
- Wraps local `git` CLI commands via `:Git` ex-command
- No remote service integration; operates on local repository only

## File System Integration

**neo-tree.nvim** (`lua/plugins/filetree.lua`):
- Uses `libuv` file watcher (`use_libuv_file_watcher = true`) for live filesystem monitoring
- Depends on `plenary.nvim` and `nui.nvim` for async I/O and UI rendering

**toggleterm.nvim** (`lua/plugins/terminal.lua`):
- Spawns local shell processes within Neovim
- Uses the system default shell

## External Binary Dependencies (NOT managed by Mason)

These tools must be installed separately on the system:

| Tool | Required By | Notes |
|------|-------------|-------|
| `git` | lazy.nvim bootstrap, gitsigns, fugitive | Core requirement |
| `rustfmt` | conform.nvim (`lua/plugins/formatting.lua`) | Install via `rustup component add rustfmt` |
| `terraform` | conform.nvim (`terraform_fmt`) | Binary provides both LSP and formatting |
| C compiler (gcc/clang) | nvim-treesitter `:TSUpdate` | Compiles tree-sitter parsers from C source |

## Data Storage

**Databases:** None (editor configuration only)

**File Storage:**
- Plugin data: `vim.fn.stdpath("data")` (typically `~/.local/share/nvim/`)
- Undo files: enabled via `opt.undofile = true` in `lua/config/options.lua`
- Swap files: disabled via `opt.swapfile = false` in `lua/config/options.lua`
- Lockfile: `lazy-lock.json` (gitignored, stores pinned plugin commit hashes)

**Caching:** None (Neovim handles its own bytecode caching)

## Authentication & Identity

Not applicable. No external service authentication.

## Monitoring & Observability

**LSP Progress:**
- `fidget.nvim` v1.6.1 (`lua/plugins/diagnostics.lua`) displays LSP server progress notifications

**Diagnostics:**
- `trouble.nvim` v3 (`lua/plugins/diagnostics.lua`) aggregates LSP and linter diagnostics into a navigable panel

**No external error tracking, logging services, or telemetry.**

## CI/CD & Deployment

**Hosting:** Git repository (version-controlled dotfiles)

**CI Pipeline:** None detected

**Deployment:** Manual symlink or clone to `~/.config/nvim/`
- Working directory is `/home/cmyster/work-laptop/rc_files/.config/nvim`
- Symlinked to `~/.config/nvim` (noted in lazydev config: "config dir is symlinked")

## Environment Configuration

**Required env vars:** None (no `.env` files detected)

**Optional env vars:**
- `VIMRUNTIME` - Used by `lua_ls` config in `lua/plugins/lsp.lua` to inject Neovim runtime types

## Network Access

Plugins that fetch data from the internet:
- **lazy.nvim** - Clones plugin repositories from GitHub on install/update
- **Mason** - Downloads LSP servers, formatters, linters from Mason registry
- **SchemaStore.nvim** - Schema catalog is bundled in the plugin (no runtime network calls)
- **nvim-treesitter** - Downloads and compiles parser grammars via `:TSUpdate`

All network access is install-time only. No plugins make runtime network requests during normal editing.

## Webhooks & Callbacks

**Incoming:** None
**Outgoing:** None

---

*Integration audit: 2026-03-09*
