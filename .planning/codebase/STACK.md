# Technology Stack

**Analysis Date:** 2026-03-03

## Languages

**Primary:**
- Lua (LuaJIT) - Neovim configuration and plugin development
  - Uses LuaJIT standard library (`std = "luajit"` in `.luacheckrc`)
  - Located in `lua/` directory

**Secondary (for LSP/Formatting Support):**
- C/C++ - Language server and linting support
- Python - Language server and formatting support via Ruff
- Bash/Shell - Script linting and formatting
- Rust - Language server and formatting support
- YAML, JSON - Configuration file support with Schema validation
- Terraform - Infrastructure-as-code language server support
- Dockerfile - Container configuration support
- CMake, Make - Build system syntax highlighting

## Runtime

**Environment:**
- Neovim 0.11+ (pinned by LSP config requirements)
- Runs on Linux (confirmed from environment)

**Plugin Manager:**
- lazy.nvim - Lazy plugin manager with auto-discovery
  - Bootstrap: `lua/plugins/` auto-imported
  - Source: https://lazy.folke.io/installation
  - Version: pinned to `main` branch (no version constraint)

## Frameworks

**Core Editor:**
- Neovim (base platform)

**Language Server Protocol (LSP):**
- nvim-lspconfig - Server configuration defaults
- mason.nvim - Language server installation and management
- mason-lspconfig.nvim v2 - Automatic LSP server enable with vim.lsp.config()
- SchemaStore.nvim - JSON and YAML schema catalogues for jsonls and yamlls

**Completion:**
- blink.cmp (v1.*) - Completion engine with native Rust fuzzy matching
  - Fuzzy implementation: Rust with Lua fallback
  - Includes cmdline completion for `:` and `/` modes

**Formatting:**
- conform.nvim v9 - Code formatter dispatcher
  - Async formatting with format-on-save
  - Per-filetype formatter configuration

**Linting:**
- nvim-lint - Async linter producing diagnostics
- mason-tool-installer - Binary installation for formatters and linters

**Tree-sitter:**
- nvim-treesitter (branch: master) - Syntax parsing and highlighting
  - nvim-treesitter-textobjects (branch: master) - Text object selection
  - Incremental selection support (via branch: master only)
  - Build: `:TSUpdate` compiles C parsers

**Git Integration:**
- gitsigns.nvim v2 - Gutter diff signs, staged indicators, inline blame
- vim-fugitive - Git command interface (`:Git` commands)

**UI/UX:**
- lualine.nvim - Statusline and winbar with git branch, diagnostics, LSP status
- nvim-navic - LSP-backed breadcrumb navigation (winbar)
- trouble.nvim v3 - Navigable diagnostics panel
- neo-tree.nvim (v3.x) - File tree, buffers panel, git status integration
- tokyonight.nvim - Color scheme (night variant)
- fidget.nvim v1.6.1 - LSP progress spinner (bottom-right)
- which-key.nvim v3 - Keymap discovery popup
- toggleterm.nvim - Toggleable terminal (1/3 window height)

**Quality of Life:**
- nvim-autopairs - Auto-close brackets and quotes
- indent-blankline.nvim v3 - Indent guides with scope underline
- lazydev.nvim - Neovim API completions (vim.*, vim.uv)

**Icon/UI Support:**
- nvim-web-devicons - File type icons
- nui.nvim - UI library for components
- plenary.nvim - Utility library

## Key Dependencies

**Critical:**
- blink.cmp - Patches `vim.lsp.config['*'].capabilities` for LSP integration
  - Must load before nvim-lspconfig to ensure LSP server capabilities are set
  - Dependency: friendly-snippets for VSCode-compatible snippets

**Infrastructure:**
- mason.nvim - Binary installer for 12 language servers
- mason-lspconfig.nvim - Bridges mason.nvim and nvim-lspconfig with automatic_enable
- nvim-lspconfig - Default configurations for all language servers

**Language Servers (auto-installed via mason):**
- clangd - C/C++ language server
- pyright - Python language server
- lua_ls - Lua language server (configured for LuaJIT + VIMRUNTIME)
- bashls - Bash language server
- yamlls - YAML language server (SchemaStore integration)
- dockerls - Dockerfile language server
- terraformls - Terraform language server
- jsonls - JSON language server (SchemaStore integration)
- rust_analyzer - Rust language server

**Formatters (auto-installed via mason-tool-installer):**
- clang-format - C/C++ formatter
- ruff - Python linter and formatter (dual-use: ruff_fix, ruff_format, ruff_organize_imports for conform)
- stylua - Lua formatter
- shfmt - Bash/shell formatter
- prettier - YAML and JSON formatter
- rustfmt - Rust formatter (installed via Rust toolchain, not mason)
- terraform - Terraform formatter (via terraformls, not separate mason package)

**Linters (auto-installed via mason-tool-installer):**
- cpplint - C/C++ linter
- luacheck - Lua linter (reads `.luacheckrc` for configuration)
- shellcheck - Bash/shell linter
- yamllint - YAML linter
- hadolint - Dockerfile linter
- tflint - Terraform linter
- jsonlint - JSON linter

## Configuration

**Neovim Options:**
- Location: `lua/config/options.lua`
- Settings: indentation (2 spaces), line numbers, clipboard, undo, search behavior, splits

**Keymaps:**
- Location: `lua/config/keymaps.lua`
- Leader key: `<space>`
- Buffer-scoped LSP keymaps registered via LspAttach autocmd in `lua/plugins/lsp.lua`

**Autocmds:**
- Location: `lua/config/autocmds.lua`
- Diagnostic float display on CursorHold
- Linting triggers on BufReadPost and BufWritePost

**Lua Static Analysis:**
- File: `.luacheckrc`
- Standard: luajit
- Globals: `vim` (Neovim runtime)

## Build & Compilation

**Tree-sitter Parsers:**
- Build trigger: `:TSUpdate` command
- Compilation: via Neovim build system from C source
- Parsers: c, cpp, python, lua, bash, yaml, hcl, json, rust, dockerfile, cmake, make

**Rust Fuzzy Matching (blink.cmp):**
- blink.cmp v1.* uses pre-built Rust binaries
- No Rust toolchain required for this config
- Fallback: Lua implementation with warning if Rust unavailable

## Platform Requirements

**Development:**
- Neovim 0.11+ (with Lua API and vim.lsp.config support)
- Git (for vim-fugitive and gitsigns)
- Tree-sitter C compiler (for `:TSUpdate`)

**Language Support (optional):**
- C/C++ toolchain (clangd, clang-format via system or mason)
- Python 3.x (pyright, ruff)
- Lua 5.1+ (lua_ls)
- Bash (bashls, shfmt, shellcheck)
- Rust toolchain (rust-analyzer, rustfmt)
- Terraform binary (terraformls, terraform fmt)
- Docker (dockerls)
- Node.js (optional: for some LSP servers that bundle as JS)

**Terminal:**
- 256-color terminal support recommended
- termguicolors enabled in options

## Installation & Startup

**First Launch:**
- lazy.nvim auto-clones from https://github.com/folke/lazy.nvim.git (stable branch)
- Plugins auto-discovered from `lua/plugins/`
- mason.nvim auto-installs configured language servers and tools
- Tree-sitter compiles parsers on first `:TSUpdate`

**Plugin Lock:**
- File: `lazy-lock.json`
- Contains commit hashes for reproducible plugin versions
- Updated via `:Lazy sync` or `:Lazy update`

---

*Stack analysis: 2026-03-03*
