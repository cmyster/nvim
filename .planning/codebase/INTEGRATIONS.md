# External Integrations

**Analysis Date:** 2026-03-08

## APIs & External Services

**Plugin Registry (GitHub):**
- lazy.nvim fetches plugins from GitHub repositories on first install and updates
  - Bootstrap: clones `https://github.com/folke/lazy.nvim.git` in `init.lua`
  - All 29 plugins sourced from GitHub (see `lazy-lock.json`)
  - No private registries or alternative sources

**Mason Registry:**
- mason.nvim downloads LSP servers, formatters, and linters from the Mason package registry
  - Registry URL: default Mason registry (GitHub-hosted)
  - Installs to: `vim.fn.stdpath("data") .. "/mason/"`
  - 9 LSP servers + 5 formatters + 8 linters auto-installed on first launch

**SchemaStore.nvim:**
- Provides JSON and YAML schema catalogues to `jsonls` and `yamlls` LSP servers
  - Schemas fetched by the LSP servers at runtime for validation/completion
  - Used in: `lua/plugins/lsp.lua` (yamlls and jsonls `vim.lsp.config()` blocks)

## Data Storage

**Databases:**
- None

**File Storage:**
- Neovim undo files: `vim.opt.undofile = true` (persistent undo across sessions)
  - Location: Neovim default `undodir` (typically `~/.local/state/nvim/undo/`)
- Mason tool storage: `vim.fn.stdpath("data") .. "/mason/"` (typically `~/.local/share/nvim/mason/`)
- lazy.nvim plugin storage: `vim.fn.stdpath("data") .. "/lazy/"` (typically `~/.local/share/nvim/lazy/`)
- Treesitter parser storage: managed by nvim-treesitter in Neovim data directory
- No swap files: `vim.opt.swapfile = false`

**Caching:**
- None (no explicit caching layer; Neovim handles internal caching)

## Authentication & Identity

**Auth Provider:**
- Not applicable (editor configuration, no user authentication)

## Monitoring & Observability

**Error Tracking:**
- None (no external error reporting)

**LSP Progress:**
- fidget.nvim v1.6.1 displays LSP `$/progress` notifications as a bottom-right spinner
  - Config: `lua/plugins/diagnostics.lua`
  - Loaded on: `LspAttach` event

**Diagnostics Display:**
- vim.diagnostic (built-in) with custom config in `lua/plugins/lsp.lua`
  - Signs: `E` / `W` / `I` / `H` text markers
  - Float on `CursorHold` (no inline virtual text)
- trouble.nvim v3 for navigable diagnostics panel
  - Config: `lua/plugins/diagnostics.lua`

**Logs:**
- No custom logging; relies on Neovim's built-in `:messages` and LSP log

## CI/CD & Deployment

**Hosting:**
- Local filesystem only; symlinked from `~/.config/nvim` to this repo location
- No remote deployment

**CI Pipeline:**
- None detected (no GitHub Actions, no CI config files)

**Version Control:**
- Git repository with remote `origin`
- `.gitignore` excludes `lazy-lock.json`

## Environment Configuration

**Required env vars:**
- None (no `.env` files, no environment variable dependencies in config)

**Secrets location:**
- Not applicable (no secrets or credentials)

## External Binary Dependencies

These binaries must exist on `PATH` and are NOT managed by Mason:

| Binary | Required By | Install Method |
|---|---|---|
| `git` | lazy.nvim bootstrap, gitsigns, fugitive | System package manager |
| `rust-analyzer` | LSP (may conflict with Mason-installed copy) | `rustup component add rust-analyzer` |
| `rustfmt` | conform.nvim formatting | `rustup component add rustfmt` |
| `terraform` | conform.nvim `terraform_fmt`, `terraformls` | System install |

## Webhooks & Callbacks

**Incoming:**
- Not applicable

**Outgoing:**
- Not applicable

## Inter-Plugin Communication

Key integration points where plugins depend on each other's runtime state:

**blink.cmp -> nvim-lspconfig:**
- blink.cmp patches `vim.lsp.config['*'].capabilities` before any LSP server starts
- Enforced via lazy.nvim dependency declaration in `lua/plugins/lsp.lua`

**gitsigns -> lualine:**
- lualine reads `vim.b.gitsigns_status_dict` for diff stats (added/changed/removed)
- Custom `diff_source()` function in `lua/plugins/statusline.lua` renames `changed` to `modified`

**nvim-navic -> lualine:**
- navic auto-attaches to LSP clients (`auto_attach = true`)
- lualine renders navic data in the winbar via the `"navic"` component
- Config: `lua/plugins/statusline.lua`

**SchemaStore.nvim -> yamlls/jsonls:**
- SchemaStore provides schema lists at LSP config time (lazy-loaded on demand)
- Config: `lua/plugins/lsp.lua` `vim.lsp.config()` calls

**treesitter -> nvim-autopairs:**
- autopairs uses `check_ts = true` for treesitter-aware bracket pairing
- Config: `lua/plugins/qol.lua`

**treesitter -> indent-blankline:**
- ibl uses treesitter scope detection for indent guide highlighting
- Config: `lua/plugins/qol.lua`

---

*Integration audit: 2026-03-08*
