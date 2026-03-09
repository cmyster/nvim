# Testing Patterns

**Analysis Date:** 2026-03-09

## Test Framework

**Runner:**
- No test framework is configured for this codebase
- No test files exist (no `*_spec.lua`, `*_test.lua`, or `*.test.*` files found)

**Assertion Library:**
- Not applicable

**Run Commands:**
```bash
# No test commands available
# This is a Neovim configuration repo, not an application with automated tests
```

## Static Analysis (In Lieu of Tests)

This codebase relies on static analysis and linting rather than unit tests, which is standard for Neovim configuration repositories.

**Lua Linting:**
- Tool: `luacheck` (installed via Mason, run by nvim-lint)
- Config: `.luacheckrc` at project root
- Runs on: `BufReadPost` and `BufWritePost` events (configured in `lua/plugins/linting.lua`)
- Globals declared: `vim` (LuaJIT std)

**Lua Formatting:**
- Tool: `stylua` (installed via Mason, run by conform.nvim)
- Runs on: `BufWritePre` (format-on-save) and `<leader>f` (manual)
- Config: stylua defaults (no `.stylua.toml` found)

**LSP Diagnostics:**
- `lua_ls` provides type checking and undefined-variable detection for Lua files
- Configured in `lua/plugins/lsp.lua` with Neovim runtime awareness (`vim.env.VIMRUNTIME` in library)
- `lazydev.nvim` supplements with `vim.*` API completions (`lua/plugins/completion.lua`)

## Validation Strategy

**Plugin Load Verification:**
```vim
:Lazy              " Check plugin install/load status
:checkhealth       " Run Neovim health checks for all plugins
:LspInfo           " Verify LSP servers are attached correctly
:ConformInfo       " Verify formatters are detected for current filetype
:Mason             " Verify tool installation status
```

**Manual Verification Approach:**
- Open a file of each supported filetype and verify:
  1. LSP attaches (check with `:LspInfo`)
  2. Linter runs (diagnostics appear)
  3. Formatter works (`<leader>f` or save)
  4. Treesitter highlighting activates
  5. Keymaps respond (gd, gr, K, etc.)

## Test File Organization

**Location:**
- No test directory exists
- If tests are added, follow Neovim plugin convention: `tests/` directory at project root
- Use `plenary.nvim` busted-style test runner (already a dependency in `lua/plugins/deps.lua`)

**Naming (if adding tests):**
- Use `*_spec.lua` suffix (plenary convention)
- Mirror source structure: `tests/config/helpscreen_spec.lua` for `lua/config/helpscreen.lua`

## Recommended Test Structure (If Adding Tests)

**Framework:** plenary.nvim includes a busted-compatible test harness.

**Pattern:**
```lua
-- tests/config/helpscreen_spec.lua
describe("helpscreen", function()
  local helpscreen = require("config.helpscreen")

  it("builds lines with correct header", function()
    -- plenary uses busted-style assertions
    assert.is_not_nil(helpscreen)
  end)

  it("opens and closes help window", function()
    helpscreen.open(false)
    -- verify window exists
    -- helpscreen.open(false) again to toggle close
  end)
end)
```

**Run command (if plenary tests exist):**
```bash
nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"
```

## Coverage

**Requirements:** None enforced. No coverage tooling configured.

**If adding coverage:**
- `luacov` is the standard Lua coverage tool
- Not currently installed or configured

## Test Types

**Unit Tests:**
- Not present. The only testable module with pure logic is `lua/config/helpscreen.lua` (builds UI lines, manages window lifecycle)

**Integration Tests:**
- Not present. Would require headless Neovim with plenary test harness

**E2E Tests:**
- Not used. Neovim configs are typically validated manually or via CI with `nvim --headless`

## What Should Be Tested (Priority Order)

**High Priority:**
- `lua/config/helpscreen.lua`: Has state management (timers, windows, buffers) that could regress
- Plugin spec validity: Ensure all `return` tables are valid lazy.nvim specs (catches syntax errors)

**Medium Priority:**
- `lua/config/autocmds.lua`: Verify autocmds register without error in headless mode
- `lua/config/keymaps.lua`: Verify keymaps register without conflicts

**Low Priority:**
- Plugin config functions in `lua/plugins/lsp.lua` and `lua/plugins/linting.lua`: Complex setup logic that could break on plugin updates

## CI Validation (If Adding)

```bash
# Minimal CI check: verify config loads without errors
nvim --headless -c "lua print('Config loaded successfully')" -c "qa!"

# Check for Lua syntax errors in all files
find lua/ -name "*.lua" -exec luac -p {} \;

# Run luacheck on all files
luacheck lua/ init.lua --config .luacheckrc
```

---

*Testing analysis: 2026-03-09*
