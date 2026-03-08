# Testing Patterns

**Analysis Date:** 2026-03-08

## Test Framework

**Runner:**
- No automated test framework detected
- No test files found in the repository
- No test configuration files (e.g., `busted`, `plenary.test_harness`, `mini.test`)

**Assertion Library:**
- Not applicable

**Run Commands:**
```bash
# No test commands available
```

## Test File Organization

**Location:**
- No test directory exists
- No test files detected (`*_spec.lua`, `*_test.lua`, `test_*.lua`)

## Manual Verification Approach

This is a Neovim configuration project. "Testing" is performed manually through:

**Plugin health checks:**
```vim
:checkhealth              " Run all health checks
:checkhealth lazy         " Verify lazy.nvim plugin loading
:checkhealth lspconfig    " Verify LSP server status
:checkhealth treesitter   " Verify parser installation
:ConformInfo              " Verify formatter detection per filetype
```

**LSP verification:**
```vim
:LspInfo                  " Check attached LSP clients for current buffer
:LspLog                   " View LSP client logs for debugging
:Mason                    " Open Mason UI to verify installed tools
```

**Linter verification:**
```vim
:lua print(vim.inspect(require("lint").linters_by_ft))  " Show linter mappings
```

**Plugin status:**
```vim
:Lazy                     " Open lazy.nvim UI showing all plugins and load status
:Lazy health              " Run lazy.nvim health checks
```

## Static Analysis

**luacheck:**
- Config: `.luacheckrc` at project root
- Declares `vim` as a known global
- Uses `luajit` standard library
- Max line length disabled (stylua handles formatting)
- Run manually:
```bash
luacheck lua/ init.lua    " Lint all Lua files
```

**LSP-based checking:**
- `lua_ls` provides type checking and diagnostics for Lua files
- `lazydev.nvim` (`lua/plugins/completion.lua`) provides Neovim API type hints
- `vim.lsp.config("lua_ls", ...)` in `lua/plugins/lsp.lua` configures runtime and workspace

## Test Types

**Unit Tests:**
- Not implemented. The codebase is a Neovim configuration (declarative plugin specs + keymaps), not a library with testable functions.

**Integration Tests:**
- Not implemented. No headless Neovim test harness configured.

**E2E Tests:**
- Not implemented.

## Validation Points

When modifying this configuration, verify these manually:

**After changing `lua/plugins/lsp.lua`:**
1. Open a file of the target language
2. Run `:LspInfo` -- verify server attaches
3. Test `gd` (definition), `gr` (references), `K` (hover)
4. Check `:messages` for errors

**After changing `lua/plugins/formatting.lua`:**
1. Open a file of the target language
2. Run `:ConformInfo` -- verify formatter is detected
3. Save the file -- format-on-save should trigger
4. Run `<leader>f` -- manual format should work

**After changing `lua/plugins/linting.lua`:**
1. Open a file of the target language
2. Introduce a lint violation
3. Save the file -- diagnostics should appear
4. Check `<leader>xx` for diagnostics panel

**After changing `lua/plugins/completion.lua`:**
1. Open a Lua file -- type `vim.` and verify completion popup
2. Open a Python/C/Rust file -- verify LSP completions appear
3. Test Tab/Shift-Tab navigation and Enter to accept

**After changing `lua/config/keymaps.lua` or any `keys` table:**
1. Press `<leader>` and wait -- which-key popup should show groups
2. Test the specific keymap
3. Verify `<leader>h` help screen lists the new keymap (update `lua/config/helpscreen.lua` if needed)

## Coverage

**Requirements:** None enforced. No coverage tooling.

**Gaps:**
- All plugin specs are untested programmatically
- Autocommand callbacks in `lua/config/autocmds.lua` have no automated verification
- Helpscreen state management (`lua/config/helpscreen.lua`) has toggle/timer logic that could benefit from unit tests if a test framework were adopted

## Potential Test Framework

If testing were to be added, the recommended approach for a Neovim config:

**Framework:** `plenary.busted` (already a dependency via `nvim-lua/plenary.nvim` in `lua/plugins/deps.lua`)
```bash
# Would run tests via headless Neovim
nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"
```

**Test location convention (if adopted):**
- `tests/` directory at project root
- `tests/minimal_init.lua` for minimal test bootstrap
- `tests/config/helpscreen_spec.lua` for module tests
- `tests/plugins/` for plugin integration verification

---

*Testing analysis: 2026-03-08*

