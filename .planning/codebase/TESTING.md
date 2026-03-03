# Testing Patterns

**Analysis Date:** 2026-03-03

## Test Framework

**Runner:**
- Not detected — no built-in test framework configured
- Neovim config testing approach: functional testing via runtime integration
- Static analysis: luacheck (Lua linter) used for code quality

**Assertion Library:**
- Not applicable — this is a Neovim configuration, not an application with unit tests

**Run Commands:**
```bash
nvim                    # Launch Neovim with this config
nvim --headless         # Headless mode for CI/testing
luacheck .              # Static Lua analysis using .luacheckrc rules
```

## Static Analysis Configuration

**Luacheck:**
- Config file: `.luacheckrc` at repository root
- Global declarations: `vim` declared as known global to suppress warnings in all files
- Standard: `std = "luajit"` (Neovim embeds LuaJIT, not standard Lua 5.x)
- Line length: disabled (`max_line_length = false`) because stylua handles formatting independently

**Stylua (Lua formatter):**
- Integrated via conform.nvim (`lua/plugins/formatting.lua`)
- Format trigger: BufWritePre autocommand (format-on-save)
- Manual format: `<leader>f` keymap

## Code Quality Verification

**Linting at runtime:**
- nvim-lint (`lua/plugins/linting.lua`) runs on BufReadPost and BufWritePost events
- Linters configured per filetype in `linters_by_ft` table
- Lua files: `luacheck` (same as static checker above)
- Output: diagnostics integrated with vim.diagnostic namespace (displayed alongside LSP errors)

**LSP diagnostics:**
- Multiple servers active simultaneously, diagnostics aggregated
- Linting does NOT replace LSP diagnostics — both sources contribute to diagnostic list
- Virtual text disabled in `lsp.lua`: `virtual_text = false`
- Float window shows on cursor hold: diagnostic auto-displays after 250ms delay (CursorHold autocmd)

## File Organization

**Test files location:**
- Not applicable — Neovim configuration files are not unit-tested
- Integration testing: manual functional testing via `nvim` command
- Headless testing: `nvim --headless` mode supports scripted validation

**Manual validation patterns:**
- Launch Neovim: verify all plugins load without errors
- `:checkhealth` command: built-in Neovim health check
  - Checks for required external tools (language servers, formatters, linters)
  - Verifies dependencies are installed via mason.nvim
- `:LspInfo` command: displays active LSP clients and their status
- `:ConformInfo` command: shows formatter availability per filetype

## Validation Strategy

**Startup validation:**
1. Launch config with `nvim --noplugin` to verify init.lua syntax
2. Launch full config: `nvim` and observe for any error messages
3. Check plugin installation: `:Lazy` to view plugin manager status

**Configuration testing:**
- Keymaps: test each `<leader>` prefix group for responsiveness
- Plugin initialization: verify lazy-loading triggers (file read, buffer write, keymap press)
- Formatter/linter integration: open file, save with `<leader>f` to verify format-on-save
- LSP functionality: open a supported filetype (Lua, Python, etc.) and test:
  - `gd` (goto definition)
  - `gr` (goto references)
  - `K` (hover)
  - `gR` (rename)

**Error handling verification:**
- Git integration: verify gitsigns signs display correctly in sign column
- Terminal: toggle terminal with `<leader>t`, verify sizing at 33% window height
- Autocmd failures: check `:messages` after operations like save/cursor move

## Plugin-Level Validation

**Plugin specs use declarative configuration:**
- Each plugin spec is a table with standard keys: `name`, `dependencies`, `event`, `cmd`, `keys`, `opts`, `config`
- Lazy.nvim validates specs at startup; invalid specs produce error messages

**Common validation checks:**
1. `dependencies` are valid plugin names
2. `event` strings match Neovim autocommand events (BufReadPost, BufWritePre, etc.)
3. `opts` tables match the plugin's expected configuration keys
4. `config` function parameters match plugin's setup() signature

**Example validation (from `lsp.lua`):**
- Dependencies: `"neovim/nvim-lspconfig"` must exist; referred to in vim.lsp.config() calls
- Opts key validation: `ensure_installed` must be array of server names from mason registry
- Function signature: `config = function(_, opts)` matches lazy.nvim callback style

## Linter Configuration Details

**Filetype → Linter mapping (from `linting.lua`):**
```lua
lint.linters_by_ft = {
  c          = { "cpplint" },
  cpp        = { "cpplint" },
  python     = { "ruff" },
  lua        = { "luacheck" },
  sh         = { "shellcheck" },   -- .sh without #!/bin/bash shebang
  bash       = { "shellcheck" },   -- files with #!/bin/bash shebang
  yaml       = { "yamllint" },
  dockerfile = { "hadolint" },
  terraform  = { "tflint" },
  json       = { "jsonlint" },
}
```

**Notes:**
- sh vs bash distinction: Neovim assigns "sh" filetype to files without shebang, "bash" to files with `#!/bin/bash`
- Both sh and bash map to shellcheck (single linter handles both)
- Rust: NO linter entry — rust_analyzer LSP provides all Rust diagnostics via vim.lsp

## Formatter Configuration Details

**Filetype → Formatter mapping (from `formatting.lua`):**
```lua
formatters_by_ft = {
  c          = { "clang-format" },
  cpp        = { "clang-format" },
  python     = { "ruff_fix", "ruff_format", "ruff_organize_imports" },
  lua        = { "stylua" },
  sh         = { "shfmt" },
  bash       = { "shfmt" },
  yaml       = { "prettier" },
  json       = { "prettier" },
  terraform  = { "terraform_fmt" },
  rust       = { "rustfmt" },
}
```

**Notes:**
- Python uses 3-step chain: lint fixes, format, organize imports
- clang-format uses hyphen (NOT clang_format with underscore) — conform v9 renamed
- terraform_fmt uses underscore — conform's name for `terraform fmt` command
- rustfmt managed via rustup (NOT via mason) to avoid duplicates; conform finds via PATH
- LSP fallback: when no formatter configured for filetype, LSP formatter used if available

## Diagnostic Display

**Configuration (from `lsp.lua`):**
```lua
vim.diagnostic.config({
  severity_sort = true,              -- sort diagnostics by severity
  update_in_insert = false,          -- don't update while typing
  signs = {                          -- gutter signs per severity
    text = {
      [vim.diagnostic.severity.ERROR] = "E",
      [vim.diagnostic.severity.WARN] = "W",
      [vim.diagnostic.severity.INFO] = "I",
      [vim.diagnostic.severity.HINT] = "H",
    },
  },
  virtual_text = false,              -- no inline text
  float = {
    border = "rounded",
    source = "if_many",              -- show source only if multiple diagnostics
  },
})
```

**Display behavior:**
- Gutter signs: E/W/I/H characters in sign column (left margin)
- Float window: auto-shows on CursorHold (250ms delay) with rounded border
- Multiple diagnostics: source (LSP or linter) shown only if >1 source contributing
- No inline virtual text: reduces visual clutter

## Trouble.nvim (Diagnostics Panel)

**Usage:**
- `:Trouble diagnostics toggle` — project-wide diagnostics panel
- `:Trouble diagnostics toggle filter.buf=0` — buffer-scoped diagnostics
- Keymaps: `<leader>xx` (project), `<leader>xX` (buffer)

**Behavior:**
- Navigable list of all diagnostics
- Click to jump to location
- Syntax: v3 commands; v2 names (workspace_diagnostics, document_diagnostics) removed

## Autocmd Testing

**Autocmd safety pattern:**
- All autocmds use named augroups with `clear = true`
- Example: `vim.api.nvim_create_augroup("project-lsp-attach", { clear = true })`
- Benefit: `:source` or `:Lazy reload` does NOT create duplicate autocmds

**Verification:**
- `:autocmd` (no args) lists all autocmds
- `:autocmd AugroupName` shows only augroup's autocmds
- Named augroups allow safe reload: clearing and re-registering prevents duplication

## Plugin Dependency Testing

**Lazy.nvim dependency resolution:**
- Declared in `dependencies` key: `dependencies = { "plugin/name", { "other/plugin", opts = {...} } }`
- Example from `lsp.lua`:
  ```lua
  dependencies = {
    { "mason-org/mason.nvim", opts = {} },
    "neovim/nvim-lspconfig",
    "saghen/blink.cmp",  -- CRITICAL: blink.cmp must load first to patch capabilities
  }
  ```
- Load order: dependencies load BEFORE the plugin declaring them
- Tests: verify plugins load in expected order via `:Lazy` status view

## Headless Testing (CI/Automation)

**Headless Neovim invocation:**
```bash
nvim --headless -c 'source ~/.config/nvim/init.lua' +quit
```

**Purpose:**
- Verify config loads without errors
- Validate all plugins install successfully
- Can be integrated into pre-commit hooks or CI pipelines

**Success criteria:**
- Exit code 0 (no errors)
- `:messages` output contains no "ERROR" or "Error" lines
- Lazy.nvim reports all plugins installed successfully

## Coverage

**Requirements:** No formal coverage requirement for this codebase

**Why:** This is a Neovim configuration, not an application. Testing focuses on:
- Functional validation (keymaps work, plugins initialize)
- Integration testing (plugins work together)
- Static analysis (luacheck passes)
- Manual QA (manual feature testing before committing)

**Code quality assurance approach:**
1. Static analysis: luacheck (.luacheckrc)
2. Format consistency: stylua (enforce via format-on-save)
3. Runtime linting: nvim-lint (multiple linters per filetype)
4. LSP diagnostics: language servers provide type/syntax checking
5. Functional testing: manual interactive testing in Neovim
6. Headless validation: config loads without errors

---

*Testing analysis: 2026-03-03*
