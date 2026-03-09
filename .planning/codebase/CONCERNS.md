# Codebase Concerns

**Analysis Date:** 2026-03-09

## Tech Debt

**Helpscreen hardcoded keybinding list:**
- Issue: `lua/config/helpscreen.lua` `build_lines()` (line 8-48) contains a manually maintained list of keybindings that must be updated by hand whenever keymaps change elsewhere. There is no mechanism to auto-generate or validate this list against actual keymap definitions in `lua/config/keymaps.lua`, `lua/plugins/lsp.lua`, `lua/plugins/filetree.lua`, `lua/plugins/git.lua`, etc.
- Files: `lua/config/helpscreen.lua`
- Impact: Help screen becomes stale as keybindings are added, changed, or removed. Users see incorrect information. The helpscreen already shows `<leader>b` as "Toggle buffers panel" but `lua/config/keymaps.lua` also maps `<leader>bd`, `<leader>bn`, `<leader>bp` for buffer management -- these overlap in the `<leader>b` namespace (neo-tree buffers panel vs buffer delete/next/prev).
- Fix approach: Either auto-generate from which-key registry at runtime, or add a comment convention linking each helpscreen entry to its source file so reviewers can verify consistency.

**Treesitter branch pinning fragility:**
- Issue: `lua/plugins/treesitter.lua` pins both `nvim-treesitter` and `nvim-treesitter-textobjects` to `branch = "master"` with a prominent warning comment about API incompatibility with the `main` branch. This creates a long-term maintenance burden -- the `master` branch may eventually be deprecated or removed.
- Files: `lua/plugins/treesitter.lua`
- Impact: If the upstream project deprecates the `master` branch, the config will need a migration to the `main` branch API (different setup function signatures, removed `incremental_selection`, different `ensure_installed` handling). The comment at the top warns about this but offers no migration path.
- Fix approach: Monitor upstream nvim-treesitter releases. When migrating, replace `require("nvim-treesitter.configs").setup()` with the new `main` branch API and remove `incremental_selection` config block.

**Duplicate dependency declarations:**
- Issue: `lua/plugins/deps.lua` declares `plenary.nvim`, `nui.nvim`, and `nvim-web-devicons` as lazy shared dependencies. However, `lua/plugins/filetree.lua` re-declares all three as dependencies of neo-tree, and `lua/plugins/statusline.lua` re-declares `nvim-web-devicons`. Lazy.nvim deduplicates these, so it works, but it creates confusion about which file is the source of truth.
- Files: `lua/plugins/deps.lua`, `lua/plugins/filetree.lua`, `lua/plugins/statusline.lua`
- Impact: No runtime impact (lazy.nvim handles dedup), but makes maintenance harder. A developer might remove a dep from `deps.lua` thinking it is unused, or vice versa.
- Fix approach: Choose one pattern: either always declare deps inline with the plugin that needs them (and remove `deps.lua`), or always reference `deps.lua` and remove inline `dependencies` lists. The inline approach is more conventional in the lazy.nvim ecosystem.

**vim-fugitive loaded eagerly with no keymaps:**
- Issue: `lua/plugins/git.lua` loads `vim-fugitive` with `lazy = false` but defines no keymaps or commands for it. The comment says "author explicitly requires this" but there is no integration beyond having `:Git` available.
- Files: `lua/plugins/git.lua`
- Impact: Adds startup time cost (~5-15ms) for a plugin that may rarely be used interactively. No keybindings are exposed in the helpscreen or which-key spec.
- Fix approach: Either add `cmd = { "Git", "G" }` for lazy-loading (loads only when `:Git` is typed), or add keymaps and document them in the helpscreen. If the eager loading is truly required for autocommands, document which autocommands depend on it.

## Known Bugs

**`<leader>b` keymap conflict between neo-tree buffers and buffer management:**
- Symptoms: Pressing `<leader>b` opens the neo-tree buffers panel (from `lua/plugins/filetree.lua`), which shadows the which-key "Buffer" group prefix (from `lua/plugins/qol.lua` line 13). The `<leader>bd`, `<leader>bn`, `<leader>bp` mappings in `lua/config/keymaps.lua` still work because they are longer sequences, but which-key shows confusing overlapping entries.
- Files: `lua/plugins/filetree.lua` (line 17), `lua/config/keymaps.lua` (lines 20-22), `lua/plugins/qol.lua` (line 13)
- Trigger: Press `<leader>b` and observe which-key popup showing both "Toggle buffers panel" and buffer sub-commands.
- Workaround: The buffer management keymaps (`bd`, `bn`, `bp`) still fire if typed quickly enough before which-key timeout. But the UX is confusing.

**Strip-whitespace autocmd applies to all filetypes including binary-adjacent:**
- Symptoms: The `BufWritePre` autocmd in `lua/config/autocmds.lua` (line 24-33) runs `%s/\s\+$//e` on every file save with `pattern = "*"`. This could modify files where trailing whitespace is significant (Markdown hard line breaks, patch files, etc.).
- Files: `lua/config/autocmds.lua` (lines 24-33)
- Trigger: Edit a Markdown file, add two trailing spaces for a hard line break, save.
- Workaround: None currently. The autocmd runs unconditionally.

## Security Considerations

**Clipboard set to unnamedplus globally:**
- Risk: `lua/config/options.lua` line 23 sets `clipboard = "unnamedplus"`, which means every yank operation copies to the system clipboard. In a shared terminal/SSH session, sensitive data yanked in Neovim is exposed to any process reading the clipboard.
- Files: `lua/config/options.lua`
- Current mitigation: None.
- Recommendations: This is a deliberate user choice and acceptable for personal configs. Be aware when editing sensitive files.

**Mason installs binaries from external sources:**
- Risk: `lua/plugins/linting.lua` and `lua/plugins/lsp.lua` auto-install 9 LSP servers and 7 linter/formatter binaries via Mason on first launch. These are downloaded from GitHub releases and npm registries without pinned checksums.
- Files: `lua/plugins/lsp.lua` (ensure_installed list), `lua/plugins/linting.lua` (ensure_installed list)
- Current mitigation: Mason uses its own registry with known download URLs. `lazy-lock.json` pins plugin versions but not Mason tool versions.
- Recommendations: Mason tool versions are not locked. After initial setup, run `:MasonLog` to verify installed versions. Consider using mason-tool-installer's `auto_update = false` (which is the default) to prevent unexpected binary changes.

## Performance Bottlenecks

**CursorHold diagnostic float on every cursor rest:**
- Problem: `lua/plugins/lsp.lua` lines 36-41 open a diagnostic float on every `CursorHold` event. With `updatetime = 250` (set in `lua/config/options.lua` line 37), this fires every 250ms of cursor inactivity. In buffers with many diagnostics, this creates frequent floating window creation/destruction cycles.
- Files: `lua/plugins/lsp.lua` (lines 36-41), `lua/config/options.lua` (line 37)
- Cause: `vim.diagnostic.open_float()` is called unconditionally on `CursorHold`, even when the cursor is not on a diagnostic line. The function returns early when there are no diagnostics, but still performs the check.
- Improvement path: Add a guard that checks `vim.diagnostic.get(0, { lnum = vim.api.nvim_win_get_cursor(0)[1] - 1 })` before calling `open_float`. This avoids creating the float entirely when the cursor line has no diagnostics.

**Format-on-save timeout at 500ms:**
- Problem: `lua/plugins/formatting.lua` line 76 sets `timeout_ms = 500` for format-on-save. For large files or slow formatters (e.g., `prettier` on large JSON), this can cause a noticeable pause on every save. If the timeout is exceeded, the format is silently skipped, leading to inconsistent formatting.
- Files: `lua/plugins/formatting.lua` (line 76)
- Cause: Synchronous format-on-save blocks the UI thread.
- Improvement path: Increase timeout to 1000ms for reliability, or switch to async formatting with `format_after_save` (conform.nvim supports this) for non-blocking saves. The tradeoff is that the file is saved unformatted and then re-saved after formatting completes.

## Fragile Areas

**LSP plugin load order:**
- Files: `lua/plugins/lsp.lua`, `lua/plugins/completion.lua`
- Why fragile: blink.cmp MUST load before any LSP server starts to patch `vim.lsp.config['*'].capabilities`. This is enforced by declaring `"saghen/blink.cmp"` as a dependency of mason-lspconfig in `lua/plugins/lsp.lua` line 92. If this dependency is accidentally removed or if another plugin triggers an LSP server start earlier, completion capabilities will be missing silently (no error, just no completions).
- Safe modification: Never remove blink.cmp from the mason-lspconfig dependencies list. If adding a new LSP-related plugin, ensure it does not call `vim.lsp.enable()` or `lspconfig[server].setup()` before blink.cmp has loaded.
- Test coverage: No automated tests. Verify by opening a file with an LSP server attached and checking `:lua =vim.lsp.get_clients()[1].server_capabilities` for completionProvider.

**Treesitter master branch API coupling:**
- Files: `lua/plugins/treesitter.lua`
- Why fragile: The entire treesitter config uses the `master` branch API (`require("nvim-treesitter.configs").setup()`). The `main` branch has a completely different API. Textobjects configuration is embedded inside the treesitter setup call (line 49-62), which is the `master` branch pattern -- the `main` branch uses a separate `.setup()` call.
- Safe modification: Do not change `branch = "master"` without rewriting the entire config function. Do not add new treesitter modules without verifying they exist in the `master` branch API.
- Test coverage: None. Open a Lua/Python file and verify syntax highlighting, then try `vaf` (select function) to verify textobjects work.

**Helpscreen module state management:**
- Files: `lua/config/helpscreen.lua`
- Why fragile: Uses module-level state variables (`help_buf`, `help_win`, `auto_close_timer` at lines 51-53) that persist across the module lifetime. If the buffer or window is closed externally (e.g., by `:bdelete` or another plugin), the module state becomes stale -- `help_win` still holds an old window ID. The `close_help()` function does check `vim.api.nvim_win_is_valid()` (line 61), but the `M.open()` toggle check on line 73 could incorrectly think the window is still open if the window was replaced by another window with the same ID (rare but possible).
- Safe modification: Always go through `close_help()` to dismiss. Do not manually close the help buffer/window.
- Test coverage: None.

## Scaling Limits

**Single-file plugin architecture:**
- Current capacity: Each plugin domain (LSP, completion, formatting, etc.) is a single file. This works well at the current ~1100 total lines across 17 Lua files.
- Limit: If per-language LSP configuration grows significantly (e.g., adding 10+ language-specific settings), `lua/plugins/lsp.lua` (already the largest file at 158 lines) will become unwieldy.
- Scaling path: Split per-server `vim.lsp.config()` calls into separate files under `lua/plugins/lsp/` with an `init.lua` that loads them.

## Dependencies at Risk

**nvim-navic may be superseded:**
- Risk: `nvim-navic` (used in `lua/plugins/statusline.lua` for winbar breadcrumbs) has not seen major updates recently. Neovim 0.11+ ships native LSP `textDocument/documentSymbol` support that could replace navic's functionality.
- Impact: If navic becomes unmaintained, the winbar breadcrumbs will stop working on future Neovim versions.
- Migration plan: Replace with lualine's built-in `aerial` or `navic` component, or use Neovim's native symbol API with a custom winbar function.

**plenary.nvim deprecation trajectory:**
- Risk: `plenary.nvim` is a widely-used utility library but its author (TJ DeVries) has indicated it may not receive major updates. It is a dependency of neo-tree (via `lua/plugins/filetree.lua`).
- Impact: If plenary breaks on a future Neovim version, neo-tree and any other plugin depending on it would need updates.
- Migration plan: Monitor neo-tree releases for plenary dependency removal. No action needed currently.

## Test Coverage Gaps

**No automated testing infrastructure:**
- What's not tested: The entire Neovim configuration has zero automated tests. There are no test files, no test framework, and no CI pipeline.
- Files: All files under `lua/`
- Risk: Any change (plugin update, keymap modification, option change) can silently break functionality. Regressions are only caught through manual use.
- Priority: Low -- this is a personal Neovim configuration, not a library. Manual verification after changes is the standard practice for dotfiles. However, adding a minimal smoke test (e.g., `nvim --headless -c "lua require('config.options')" -c "qa"`) to CI would catch syntax errors and missing modules.

---

*Concerns audit: 2026-03-09*
