-- lua/plugins/diagnostics.lua
-- Diagnostic UI plugins: trouble.nvim v3 (navigable diagnostics panel) and
-- fidget.nvim v1.6.1 (LSP progress spinner).
--
-- This file is self-contained: lsp.lua requires NO changes because trouble.nvim
-- automatically subscribes to vim.diagnostic via DiagnosticChanged; the existing
-- vim.diagnostic.config() settings (severity_sort=true, virtual_text=false, signs)
-- in lsp.lua are inherited transparently.

return {
  -- trouble.nvim v3: navigable diagnostics panel
  -- lazy-loaded on first :Trouble command (zero startup cost)
  -- v3 command syntax: "Trouble {mode} toggle" — TroubleToggle is REMOVED in v3
  -- v3 mode names: "diagnostics" (project-wide), "diagnostics filter.buf=0" (buffer-scoped)
  -- OLD names workspace_diagnostics / document_diagnostics are v2-only, DO NOT use
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
    },
    opts = {},
  },

  -- fidget.nvim v1.6.1: non-intrusive LSP progress spinner (bottom-right)
  -- Pinned to v1.6.1 tag — verified stable release
  -- Loaded on LspAttach so it is ready before the first $/progress notification
  -- opts = {} is correct for v1.6.1 — defaults produce correct bottom-right spinner
  -- with auto-fade; the legacy "sources" config belongs to the removed legacy branch
  {
    "j-hui/fidget.nvim",
    tag = "v1.6.1",
    event = "LspAttach",
    opts = {},
  },
}
