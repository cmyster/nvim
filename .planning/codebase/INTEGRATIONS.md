# External Integrations

**Analysis Date:** 2026-03-03

## APIs & External Services

**GitHub Integration:**
- vim-fugitive - Git/GitHub integration via `:Git` commands
  - Configuration: `lua/plugins/git.lua`
  - Provides `:Git clone`, `:Git push`, `:Git pull`, and full git workflow

**Schema Validation:**
- SchemaStore.nvim - Online schema catalog for JSON and YAML
  - Provides schemas via https://www.schemastore.org/ (implicit)
  - Configuration: `lua/plugins/lsp.lua` (lines 116-137)
  - Usage: Injected into yamlls and jsonls servers

## Language Server Protocol (LSP)

**Remote Language Servers (network calls):**
- Servers connect to build systems and package managers for project analysis:
  - **pyright** - May connect to Python package repositories
  - **rust_analyzer** - Analyzes Rust project metadata and dependencies
  - **terraformls** - Analyzes Terraform registry for module validation

**Local Language Servers (no external network):**
- clangd, lua_ls, bashls, dockerls, jsonls, yamlls - Local only

**LSP Configuration:**
- Location: `lua/plugins/lsp.lua`
- Installed servers: 9 language servers via mason.nvim
- LSP attachment triggers: automatic via `automatic_enable = true`
- Per-server configs: lines 111-152 (yamlls, jsonls, lua_ls)

## Data Storage

**No Database Integration:**
- This is a local editor configuration
- No persistent backend data storage
- No ORM or database client libraries

**Local File System Only:**
- Operates on user's local filesystem
- neo-tree.nvim: file tree navigation (local)
- Undo/swap files: configured in `lua/config/options.lua`
  - undofile = true (persistent undo in ~/.local/share/nvim)
  - swapfile = false (no swap file)

**Plugin Lock File:**
- `lazy-lock.json` - Stores plugin version hashes (local)

## Caching

**None Detected:**
- LSP servers may cache internally (transparent to config)
- No explicit caching layer

## Authentication & Identity

**No Authentication Required:**
- Local editor configuration
- Git operations (vim-fugitive) use system git credentials
- No API keys or auth tokens needed for core functionality

**Optional:**
- GitHub SSH keys (via system ~/.ssh/config) for vim-fugitive git operations
- Git credentials helper (via system git config) for HTTPS clones

## Monitoring & Observability

**Error Tracking:**
- None detected
- Errors logged to Neovim message buffer

**Logging:**
- Diagnostic output visible in:
  - `:Trouble diagnostics` panel (via trouble.nvim)
  - `:LspInfo` - Shows active language servers and their status
  - `:ConformInfo` - Shows formatter status for current buffer
  - Console on startup (via vim.api.nvim_echo for error reporting)

**LSP Progress:**
- fidget.nvim - Shows LSP operation progress (bottom-right spinner)
- No network telemetry

## File Watchers & System Integration

**Git Monitoring:**
- gitsigns.nvim - Watches .git directory for changes
  - Configuration: `lua/plugins/git.lua` (lines 33)
  - watch_gitdir = { follow_files = true }

**File System Watching:**
- neo-tree.nvim - Watches filesystem for file changes
  - Configuration: `lua/plugins/filetree.lua` (line 26)
  - use_libuv_file_watcher = true (uses Neovim's libuv)

## Webhooks & Callbacks

**No Webhooks:**
- This is a local editor configuration
- No incoming HTTP endpoints
- No outgoing webhook subscriptions

## External Tool Invocations

**Formatter Binaries (via conform.nvim):**
- Invokes external formatter processes for each filetype:
  - `clang-format` - C/C++ formatting
  - `ruff` - Python linting, formatting, import sorting
  - `stylua` - Lua formatting
  - `shfmt` - Bash/shell formatting
  - `prettier` - YAML and JSON formatting
  - `rustfmt` - Rust formatting
  - `terraform` - Terraform formatting

**Linter Binaries (via nvim-lint):**
- Invokes external linter processes for each filetype:
  - `cpplint` - C/C++ linting
  - `luacheck` - Lua linting
  - `shellcheck` - Bash/shell linting
  - `yamllint` - YAML linting
  - `hadolint` - Dockerfile linting
  - `tflint` - Terraform linting
  - `jsonlint` - JSON linting

**Configuration:**
- Formatters configured in `lua/plugins/formatting.lua` (lines 34-63)
- Linters configured in `lua/plugins/linting.lua` (lines 74-85)
- Mason tool installer: `lua/plugins/linting.lua` (lines 22-48)

## Terminal Integration

**Toggleable Terminal:**
- toggleterm.nvim - Embedded terminal in Neovim
  - Configuration: `lua/plugins/terminal.lua`
  - Direction: Horizontal split, 33% window height
  - Keybind: `<leader>t`

## System Clipboard

**Clipboard Integration:**
- Option: `clipboard = "unnamedplus"`
- Location: `lua/config/options.lua` (line 23)
- Uses system clipboard via `+` register (unnamedplus)
- Requires `xclip` or similar system clipboard provider

## Environment Configuration

**No Environment Variables Required:**
- This is a zero-config editor setup
- No .env file needed
- LSP servers, formatters, and linters discovered via PATH

**Optional Configuration (user responsibility):**
- Git credentials (system git config)
- Language toolchains (Python, Rust, C/C++, etc.) must be on PATH

## System Dependencies

**Required (must be installed):**
- Neovim 0.11+
- Git
- Tree-sitter C compiler (for treesitter parser compilation)

**Language Toolchains (optional, for LSP/formatter support):**
- Python 3.x (for pyright, ruff)
- Rust toolchain (for rust-analyzer, rustfmt)
- C/C++ compiler (for clangd, clang-format)
- Lua 5.1+ (for lua_ls)
- Bash (for bashls, shellcheck, shfmt)
- Terraform (for terraformls, terraform fmt)
- Docker (for dockerls)

---

*Integration audit: 2026-03-03*
