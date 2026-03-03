# Codebase Concerns

**Analysis Date:** 2026-03-03

## Critical Dependencies with Version Pinning

**Treesitter Master Branch Pin:**
- Issue: Both `nvim-treesitter` and `nvim-treesitter-textobjects` are pinned to `branch = "master"` specifically because the main branch removed `incremental_selection` and `ensure_installed` configuration APIs
- Files: `lua/plugins/treesitter.lua` (lines 9, 14)
- Impact: Upgrading to main branch will cause configuration failures; users migrating to main branch face breaking changes without warning
- Fix approach: Monitor upstream for stable release or document this dependency clearly in README; consider creating issue upstream to track API stability

**Blink.cmp Load Order Dependency:**
- Issue: `blink.cmp` MUST load before `nvim-lspconfig` because it needs to patch `vim.lsp.config['*'].capabilities` before any LSP server attaches
- Files: `lua/plugins/lsp.lua` (lines 90-92), `lua/plugins/completion.lua` (lines 4-5)
- Impact: If plugin load order breaks (manual edits, future plugin conflicts), LSP completion will fail silently
- Fix approach: Add explicit validation in `lsp.lua` to check if blink.cmp has patched capabilities; fail loudly if not

**Gitsigns v2 API Dependency:**
- Issue: Configuration uses gitsigns v2 API (removed `hl` field from signs table in v2.0.0, Jan 2026)
- Files: `lua/plugins/git.lua` (line 1)
- Impact: Upgrading to future major versions with different sign table API will break git gutter display
- Fix approach: Use `version = "2.*"` constraint if not already in lazy-lock.json; add migration notes for v3

## Data Flow Fragility

**Gitsigns to Lualine Data Mapping:**
- Issue: Statusline relies on gitsigns buffer-local variable `vim.b.gitsigns_status_dict` and must manually rename `gitsigns.changed` → `lualine.modified`
- Files: `lua/plugins/statusline.lua` (lines 8-19)
- Impact: If gitsigns changes its internal status_dict structure or key names, statusline diff stats silently disappear
- Fix approach: Wrap in error handling function with fallback; add type assertion/validation before accessing dictionary keys
- Safe modification: Test after any gitsigns update; verify `git diff` stats appear in statusline

**LSP Configuration Pre-Setup Window:**
- Issue: All `vim.lsp.config()` calls MUST run before `mason-lspconfig.setup()` is called, or server configs won't be picked up by `automatic_enable`
- Files: `lua/plugins/lsp.lua` (lines 111-155)
- Impact: Reordering these blocks or splitting into separate plugin specs will break per-server settings (e.g., SchemaStore integration)
- Fix approach: Add assertion after setup to verify expected servers initialized with correct settings; document this constraint prominently

## Silent Failure Points

**Conform Formatter Name Mismatch:**
- Issue: Wrong formatter names cause silent failures — conform skips unknown formatters without error
- Files: `lua/plugins/formatting.lua` (lines 34-63)
- Current state: All names verified as correct for conform v9, but easy to break by copy/paste from other configs
- Impact: User saves file thinking formatting happens, but nothing actually reformats
- Fix approach: Add `:ConformInfo` output parsing in keymapping to verify formatters exist at startup; warn on missing

**Treesitter Parser Ensure-Install Failure:**
- Issue: Parser installation from C source via `:TSUpdate` can fail silently (network, build toolchain issues)
- Files: `lua/plugins/treesitter.lua` (line 11)
- Impact: Missing parsers degrade syntax highlighting without obvious error message
- Fix approach: Add post-config validation that all `ensure_installed` parsers compiled successfully; use `:TSCheckHealth`

**LSP Server Automatic Enable Bypass:**
- Issue: If a configured server (e.g., `rust_analyzer`) is found on PATH via rustup, `automatic_enable = true` will still activate it unless `automatic_enable = { exclude = { "rust_analyzer" } }` is set
- Files: `lua/plugins/lsp.lua` (lines 8-11, 108)
- Impact: May run two rust_analyzer instances (one from mason, one from rustup) causing conflicts or resource waste
- Fix approach: Document the rustup case explicitly; add `:LspInfo` command to statusline for quick verification

## Diagnostic Configuration Interdependency

**Float Display on CursorHold:**
- Issue: Custom `CursorHold` autocmd shows diagnostic floats, but this conflicts with some plugins (particularly those that create augroups on same event)
- Files: `lua/plugins/lsp.lua` (lines 36-41)
- Current state: Named augroup with `clear=true` prevents duplicates, but still runs on every cursor hold
- Impact: Can cause jitter or lag if many diagnostics exist; LSP server updates may trigger rapid repaints
- Fix approach: Add debounce logic or check if float already visible before creating new one; consider `updatetime` tuning (currently 250ms)

**Diagnostic Severity Sort Dependency:**
- Issue: Statusline shows error/warning/info/hint counts from lualine's diagnostics component, which respects `severity_sort = true` from lsp.lua
- Files: `lua/plugins/lsp.lua` (line 18), `lua/plugins/statusline.lua` (line 71)
- Impact: If severity_sort removed from lsp.lua, diagnostic display order changes but statusline counts remain unchanged
- Fix approach: Document that severity_sort should not be changed without updating statusline expectations

## Version Compatibility Constraints

**Conform v9 API Specifics:**
- Issue: Config uses conform v9 naming convention; v8 or earlier has different formatter names (e.g., `clang_format` vs `clang-format`)
- Files: `lua/plugins/formatting.lua` (lines 24-60)
- Current constraint: `branch = "master"` (not a tag), so may pull breaking changes
- Impact: Formatter selection fails silently on version mismatch
- Fix approach: Consider pinning to `version = "9.*"` tag instead of branch; add version guard in setup function

**Indent-Blankline v3 Module Name:**
- Issue: v3 requires `main = "ibl"` (v2 used `indent_blankline`); this is documented but easy to forget during maintenance
- Files: `lua/plugins/qol.lua` (lines 24-37)
- Impact: Forgetting this requirement after a merge will cause module load failure
- Fix approach: This is already correct; no action needed but document in CONVENTIONS

**Lualine Missing Docstring:**
- Issue: `lualine_status` component in statusline accepts `ignore_lsp` (empty table) but documentation unclear on what LSP servers to exclude
- Files: `lua/plugins/statusline.lua` (line 77)
- Impact: If user has many LSP servers, statusline may show confusing server name; no way to filter without editing config
- Fix approach: Document what `ignore_lsp` does; consider adding comment explaining which servers typically get ignored

**Trouble.nvim v3 Mode Names:**
- Issue: v3 removed workspace_diagnostics/document_diagnostics mode names; only accepts diagnostics mode with filter.buf parameter
- Files: `lua/plugins/diagnostics.lua` (lines 13-15)
- Impact: Config is correct for v3 but old code/docs reference obsolete mode names
- Fix approach: Document v3-only requirement; consider adding check that trouble.nvim version >= 3

## Plugin Interaction Risks

**Autopairs and Blink.cmp Double-Insert Prevention:**
- Issue: nvim-autopairs must NOT use a blink.cmp callback because blink.cmp already has `auto_brackets` that handles bracket closing post-completion
- Files: `lua/plugins/qol.lua` (lines 40-48)
- Current state: Correctly omits callback, but fragile — easy to add one and break auto-pairing
- Impact: Brackets inserted twice after accepting completion
- Fix approach: Add assertion/test for this interaction; document in code why callback is not used

**Terminal Key Binding Conflict:**
- Issue: `<leader>t` maps to toggleterm, but if any plugin rebinds this or registers same keymap later, terminal will not toggle
- Files: `lua/plugins/terminal.lua` (lines 9-10), `lua/config/keymaps.lua` (line 10)
- Impact: User presses `<leader>t` expecting terminal, gets unexpected command instead
- Fix approach: Use `which-key.nvim` group label enforcement; document in keymap file that `<leader>t` is reserved for terminal

**Neo-tree vs Filetree Explorer Key:**
- Issue: Both `<leader>e` and `\` map to neo-tree toggle; this is intentional but means modifying one keymap risks confusion
- Files: `lua/plugins/filetree.lua` (lines 14-15)
- Impact: If user customizes keymaps, they may forget to update both
- Fix approach: Document both keymaps clearly; consider centralizing keymap config into dedicated module if expandable

## Performance Concerns

**Virtual Text Disabled but Float Still Expensive:**
- Issue: Inline diagnostics are disabled (`virtual_text = false`) to reduce visual clutter, but float displays on every `CursorHold` (250ms timeout)
- Files: `lua/plugins/lsp.lua` (lines 28, 36-41)
- Impact: With many diagnostics, CursorHold float creation on every 250ms can add latency during active editing
- Fix approach: Profile with many open diagnostics; consider increasing `updatetime` or adding debounce to float creation

**Trailing Whitespace Cleanup Performance:**
- Issue: `BufWritePre` autocmd runs regex substitution on entire buffer before save
- Files: `lua/config/autocmds.lua` (lines 24-33)
- Impact: Large files (100K+ lines) may experience noticeable save lag
- Fix approach: Consider using built-in `trimWhitespace` option instead of regex; benchmark on very large files

**JSON Schema Store Network Fetch:**
- Issue: SchemaStore.nvim fetches remote schemas on first use; can block completion if network slow
- Files: `lua/plugins/lsp.lua` (lines 116-127)
- Current state: yamlls and jsonls configured with SchemaStore, but no timeout configured
- Impact: First JSON/YAML file in session may pause during LSP initialization
- Fix approach: Test on slow network; consider caching schemas or adding timeout to prevent hang

## Testing and Validation Gaps

**No Startup Health Check:**
- Issue: No automated validation that all expected plugins load and configure correctly at startup
- Files: All plugin files collectively
- Impact: User might not notice broken plugin until trying to use that feature
- Fix approach: Create health check function that runs `:checkhealth` on critical components; document in README

**No LSP Server Availability Validation:**
- Issue: `ensure_installed` servers may fail to install due to network/permission issues, but config doesn't detect this
- Files: `lua/plugins/lsp.lua` (lines 95-108)
- Impact: Silent failure; user has no LSP for a language without realizing
- Fix approach: Add post-setup hook that runs `:LspInfo` and validates at least one server per critical filetype

**Formatter Binary Existence Not Validated:**
- Issue: `conform.nvim` silently skips missing formatters; no validation that all `formatters_by_ft` binaries are actually installed
- Files: `lua/plugins/formatting.lua` (lines 34-63)
- Impact: User presses `<leader>f` expecting format, sees no change, thinks it worked but didn't
- Fix approach: Use `:ConformInfo` command to list available formatters; add startup warning if any expected formatter missing

## Linter Configuration Inconsistencies

**Ruff Used for Both Linting and Formatting:**
- Issue: "ruff" binary serves dual purpose — format chain uses `ruff_fix`, `ruff_format`, `ruff_organize_imports` while linter uses single `ruff` entry
- Files: `lua/plugins/linting.lua` (lines 25, 46-47), `lua/plugins/formatting.lua` (lines 40-45)
- Current state: Correct but subtle; easy to misunderstand
- Impact: User might think they need separate ruff installs or wonder why linter uses "ruff" but formatter uses three stages
- Fix approach: Add comment explaining ruff binary's dual role and that both specs reference the same `ensure_installed` entry

**No Rust Linter Declared:**
- Issue: Intentionally omitted because rust_analyzer LSP provides all diagnostics, but this could confuse future maintainers
- Files: `lua/plugins/linting.lua` (lines 73)
- Impact: New contributor might add clippy linter not realizing rust_analyzer already covers it
- Fix approach: Add explicit comment explaining why Rust linting not listed

**Bash/sh Filetype Duplication:**
- Issue: Both `sh` and `bash` filetypes map to `shellcheck` linter and `shfmt` formatter because Neovim assigns different filetypes based on shebang
- Files: `lua/plugins/linting.lua` (lines 69-72, 79-80), `lua/plugins/formatting.lua` (lines 49-52)
- Current state: Correct and documented, but requires knowledge of Neovim's filetype detection
- Impact: Removing one entry breaks half of Bash coverage
- Fix approach: Keep as-is but add clear comment about why both entries exist; consider helper function to reduce duplication

## Missing Error Context

**Empty LazyDev Enable Function:**
- Issue: LazyDev config has `enabled = function() return true end` which always enables, defeating the purpose of conditional enable
- Files: `lua/plugins/completion.lua` (lines 14-17)
- Comment explains: "config dir is symlinked so lazydev's path-matching fails"
- Impact: Slightly inefficient if lazydev's internal path detection would have disabled it anyway
- Fix approach: Document why unconditional enable is necessary; consider if symlink path can be resolved for future cleanup

**Restore Cursor Mark Bounds Check Loose:**
- Issue: `BufReadPost` cursor restoration uses `pcall()` to suppress errors if mark invalid, but silently ignores all errors
- Files: `lua/config/autocmds.lua` (lines 11-21)
- Impact: If cursor restoration fails for reason other than invalid mark (e.g., buffer type issue), user won't know
- Fix approach: Add explicit check for valid mark before pcall; log unexpected errors to debug buffer

## Dependency Duplication Risk

**Mason.nvim Declared Multiple Times:**
- Issue: `mason.nvim` is declared as dependency in both `lsp.lua` (line 87) and `linting.lua` (line 19)
- Files: `lua/plugins/lsp.lua`, `lua/plugins/linting.lua`
- Current state: lazy.nvim deduplicates, but fragile — if order changes, may install twice
- Impact: Redundant installation steps on first run; potential version conflicts if different specs pin different versions
- Fix approach: Declare mason.nvim once in dedicated location (e.g., `deps.lua`); remove from plugin-specific specs

**Plenary, NUI, DevIcons Dependencies Scattered:**
- Issue: Dependencies already declared in `deps.lua` but also repeated as dependencies in `filetree.lua`
- Files: `lua/plugins/filetree.lua` (lines 8-11)
- Current state: Works due to deduplication, but maintenance burden
- Fix approach: Remove from filetree.lua; rely on deps.lua only

---

*Concerns audit: 2026-03-03*
