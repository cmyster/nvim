# Codebase Concerns

**Analysis Date:** 2026-03-08

## Tech Debt

**Helpscreen hardcoded keybinding list:**
- Issue: `lua/config/helpscreen.lua` `build_lines()` (line 8) maintains a manually written list of keybindings that must be kept in sync with actual keymaps defined across `lua/config/keymaps.lua`, `lua/plugins/lsp.lua`, `lua/plugins/filetree.lua`, `lua/plugins/git.lua`, `lua/plugins/formatting.lua`, `lua/plugins/diagnostics.lua`, and `lua/plugins/terminal.lua`. Any new keymap added to a plugin file must also be manually added to the help screen.
- Files: `lua/config/helpscreen.lua`
- Impact: Help screen silently becomes stale when keymaps are added or changed. Users see incorrect documentation. The `<leader>b` key in the help screen says "Toggle buffers panel" but `lua/config/keymaps.lua` also defines `<leader>bd`, `<leader>bn`, `<leader>bp` for buffer management. The neo-tree `<leader>b` mapping in `lua/plugins/filetree.lua` overrides the buffer-prefix group.
- Fix approach: Either auto-generate the help screen from `vim.api.nvim_get_keymap()` at display time, or accept the maintenance burden and add a comment checklist in the helpscreen file listing all source files to check.

**Helpscreen auto-close timer changed from 3s to 7s without updating comment:**
- Issue: The module-level comment in `lua/config/helpscreen.lua` (line 3) says "auto-closes after 3s" but the actual timer on line 112 is set to 7000ms.
- Files: `lua/config/helpscreen.lua` lines 3, 112
- Impact: Comment misleads future maintainers. Minor but indicates documentation drift.
- Fix approach: Update the comment on line 3 to say "7s" or make the timeout a local variable referenced by both comment and code.

**Treesitter branch pinning requires vigilance:**
- Issue: `lua/plugins/treesitter.lua` pins both `nvim-treesitter` and `nvim-treesitter-textobjects` to `branch = "master"` with a prominent warning comment (lines 3-5) about API differences between branches. The `main` branch removed `incremental_selection` and `ensure_installed`. This is a conscious decision but creates an ongoing maintenance concern: upstream may deprecate the master branch or change its API.
- Files: `lua/plugins/treesitter.lua`
- Impact: If the master branch is removed or diverges significantly, the treesitter config breaks entirely. The `textobjects` config block uses master-only API (configured inside `configs.setup()` rather than via separate `require("nvim-treesitter-textobjects").setup()`).
- Fix approach: Monitor nvim-treesitter releases. If master is deprecated, migrate to main branch API: replace `ensure_installed` with `vim.treesitter.install()` calls, replace `incremental_selection` with native Neovim selection APIs, and move textobjects config to standalone setup call.

**vim-fugitive loaded eagerly with no keymaps or commands configured:**
- Issue: `lua/plugins/git.lua` loads `tpope/vim-fugitive` with `lazy = false` (line 65) but defines zero keymaps, zero which-key group entries, and no user-facing configuration. The plugin is available only via typing `:Git` manually.
- Files: `lua/plugins/git.lua`
- Impact: Adds startup time for a plugin with no configured keybindings. Users must know fugitive commands already. No discoverability via which-key or the help screen.
- Fix approach: Either add `<leader>g` keymaps for common fugitive commands (`:Git status`, `:Git diff`, `:Git log`) and register them in which-key and the helpscreen, or lazy-load fugitive with `cmd = { "Git", "G" }` if the autocommand concern is no longer valid.

**Duplicate dependency declarations:**
- Issue: `lua/plugins/deps.lua` declares `plenary.nvim`, `nui.nvim`, and `nvim-web-devicons` as shared lazy dependencies. However, `lua/plugins/filetree.lua` re-declares the same three as explicit dependencies of neo-tree (lines 9-11), and `lua/plugins/statusline.lua` re-declares `nvim-web-devicons` (line 51). lazy.nvim deduplicates these, so there is no runtime bug, but it creates maintenance confusion about which file is the canonical source.
- Files: `lua/plugins/deps.lua`, `lua/plugins/filetree.lua`, `lua/plugins/statusline.lua`
- Impact: No runtime impact (lazy.nvim deduplicates). Creates confusion about where to update dependency versions or settings.
- Fix approach: Choose one approach: either declare all shared deps only in `deps.lua` and remove them from individual plugin specs, or remove `deps.lua` entirely and let each plugin declare its own dependencies (the more standard lazy.nvim pattern).

## Known Bugs

**`<leader>b` keymap conflict between keymaps.lua and filetree.lua:**
- Symptoms: Pressing `<leader>b` opens the neo-tree buffers panel (from `lua/plugins/filetree.lua` line 16) instead of being available as a prefix for `<leader>bd`, `<leader>bn`, `<leader>bp` (from `lua/config/keymaps.lua` lines 20-22). which-key shows `<leader>b` as "Buffer" group but the immediate mapping fires neo-tree before the submenu can appear.
- Files: `lua/config/keymaps.lua` lines 20-22, `lua/plugins/filetree.lua` line 16
- Trigger: Press `<leader>b` in normal mode.
- Workaround: Use `:bnext`, `:bprevious`, `:bdelete` commands directly, or remap the buffer panel to a different key (e.g., `<leader>B`).

**Strip-whitespace autocmd runs on all filetypes including binary-adjacent files:**
- Symptoms: The `BufWritePre` autocmd in `lua/config/autocmds.lua` (lines 24-33) uses `pattern = "*"` which means it runs `%s/\s\+$//e` on every file save, including files where trailing whitespace may be significant (e.g., Markdown where double-trailing-space means `<br>`, or patch files).
- Files: `lua/config/autocmds.lua` lines 24-33
- Trigger: Save any Markdown file with intentional trailing whitespace.
- Workaround: None currently. Add a filetype exclusion list or use a conditional check.

## Security Considerations

**No sensitive files detected in repository:**
- Risk: Low. This is a Neovim configuration with no secrets, API keys, or credentials. The `.gitignore` only excludes `lazy-lock.json`.
- Files: `.gitignore`
- Current mitigation: No `.env` files exist. No credential files detected.
- Recommendations: If environment-specific overrides are ever needed, add a `local.lua` pattern to `.gitignore` before creating any such files.

**Clipboard set to system clipboard by default:**
- Risk: `lua/config/options.lua` line 23 sets `clipboard = "unnamedplus"`, meaning every yank operation copies to the system clipboard. If editing files containing sensitive content (passwords, tokens), yanked text goes to the OS clipboard where other applications can read it.
- Files: `lua/config/options.lua` line 23
- Current mitigation: None. This is standard Neovim config behavior.
- Recommendations: Be aware when editing sensitive files. Use `"+` register explicitly if clipboard isolation is needed.

## Performance Bottlenecks

**CursorHold diagnostic float fires on every cursor rest:**
- Problem: `lua/plugins/lsp.lua` lines 36-41 create a `CursorHold` autocmd that calls `vim.diagnostic.open_float()` on every cursor rest event (governed by `updatetime = 250ms` from `lua/config/options.lua` line 37). This creates a floating window even when no diagnostics exist at the cursor position.
- Files: `lua/plugins/lsp.lua` lines 36-41, `lua/config/options.lua` line 37
- Cause: `vim.diagnostic.open_float()` is called unconditionally. With `updatetime = 250`, this fires frequently during normal editing pauses.
- Improvement path: Guard the call with a check: only open the float if `vim.diagnostic.get(0, { lnum = vim.api.nvim_win_get_cursor(0)[1] - 1 })` returns non-empty results. This avoids creating and immediately discarding empty float windows.

**Format-on-save with 500ms timeout:**
- Problem: `lua/plugins/formatting.lua` line 76 sets `timeout_ms = 500` for format-on-save. For large files or slow formatters (e.g., `prettier` on large JSON), this may cause the save to feel sluggish or the formatter to be killed mid-run.
- Files: `lua/plugins/formatting.lua` line 76
- Cause: Synchronous formatting blocks the UI thread during save.
- Improvement path: Increase timeout to 1000ms for reliability, or switch to async formatting with `format_after_save` instead of `format_on_save` for a non-blocking experience.

## Fragile Areas

**LSP plugin load order dependency chain:**
- Files: `lua/plugins/lsp.lua`, `lua/plugins/completion.lua`
- Why fragile: The LSP setup has a strict load order requirement: blink.cmp must load before mason-lspconfig runs, so it can patch `vim.lsp.config['*'].capabilities`. This is enforced via the `dependencies` list in `lua/plugins/lsp.lua` line 92. Additionally, `vim.lsp.config()` calls (lines 117-152) must run before `require("mason-lspconfig").setup()` (line 155) inside the same `config` function. Reordering these calls or moving them to separate files silently breaks LSP capabilities.
- Safe modification: When adding a new LSP server, add its name to `ensure_installed` (line 95) and optionally add a `vim.lsp.config("server_name", { ... })` call before the `require("mason-lspconfig").setup(opts)` line. Do not move the `vim.lsp.config()` calls outside the `config` function.
- Test coverage: No automated tests. Verify with `:LspInfo` after changes.

**Conform formatter name sensitivity:**
- Files: `lua/plugins/formatting.lua` lines 34-63
- Why fragile: Conform silently skips unknown formatter names. If a formatter name changes between conform versions (as happened with `clang_format` -> `clang-format` in v9), formatting silently stops working for that filetype with no error message.
- Safe modification: After adding or changing a formatter name, run `:ConformInfo` to verify the formatter is detected and available.
- Test coverage: No automated tests. Manual verification via `:ConformInfo` only.

**Linting autocmd event matching:**
- Files: `lua/plugins/linting.lua` lines 62-64, 89
- Why fragile: The `event` table for lazy-loading (line 64) must exactly match the events in the `nvim_create_autocmd` call (line 89). If the lazy-load events are changed without updating the autocmd (or vice versa), linting either never loads or never triggers.
- Safe modification: Always update both the `event` table and the autocmd events together.
- Test coverage: None. Verify by opening a file and checking `:lua print(vim.inspect(vim.diagnostic.get(0)))` for lint diagnostics.

## Scaling Limits

**No telescope or fuzzy finder configured:**
- Current capacity: File navigation relies entirely on neo-tree (tree view) and manual `:edit` commands.
- Limit: In large projects with deep directory structures, navigating without a fuzzy file finder becomes impractical.
- Scaling path: Add telescope.nvim or fzf-lua for fuzzy file finding, live grep, and buffer switching.

## Dependencies at Risk

**Treesitter master branch:**
- Risk: The `master` branch of nvim-treesitter is the legacy branch. The project has been migrating functionality to `main`. Pinning to `master` means relying on a branch that may stop receiving updates.
- Impact: Loss of new parser support, potential security fixes missed, eventual incompatibility with newer Neovim versions.
- Migration plan: Monitor nvim-treesitter releases. When master is officially deprecated, migrate to main branch API (see Tech Debt section above).

**fidget.nvim pinned to specific tag:**
- Risk: `lua/plugins/diagnostics.lua` pins fidget.nvim to `tag = "v1.6.1"`. This prevents receiving bug fixes and compatibility updates.
- Impact: Low. fidget.nvim is a UI-only plugin with minimal integration surface.
- Migration plan: Periodically update the tag to the latest stable release, or switch to `branch = "main"` for rolling updates.

## Missing Critical Features

**No fuzzy finder (telescope/fzf-lua):**
- Problem: No fuzzy file finder, live grep, or searchable buffer list is configured.
- Blocks: Quick file navigation in large projects, searching across files, finding symbols project-wide.

**No search-and-replace workflow:**
- Problem: No spectre.nvim or similar project-wide search-and-replace plugin is configured.
- Blocks: Bulk renaming or refactoring across multiple files requires manual `:grep` and `:cdo` commands.

**No session management:**
- Problem: No auto-session or persistence plugin configured. Closing Neovim loses all open buffers, window layouts, and cursor positions (aside from the single-file cursor restore in `lua/config/autocmds.lua`).
- Blocks: Quick resumption of work context after closing the editor.

## Test Coverage Gaps

**No automated tests exist:**
- What's not tested: The entire configuration. There are no unit tests, integration tests, or CI pipeline.
- Files: All files under `lua/`
- Risk: Configuration changes (especially to LSP load order, formatter names, or autocmd logic) can silently break functionality with no automated detection. Breakage is only discovered through manual usage.
- Priority: Low for a personal Neovim config. Medium if this config is shared across machines or with other users.

---

*Concerns audit: 2026-03-08*

