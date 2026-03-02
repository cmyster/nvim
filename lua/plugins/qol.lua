-- lua/plugins/qol.lua
-- Quality-of-life plugins: keymap discoverability, indent guides, auto-pairs
-- NOTE: QOL-04 (Lua API completions) is already declared in completion.lua — do NOT add it here.
return {
  -- which-key.nvim: keymap popup on leader-key pause
  -- v3 API: use opts.spec for group labels; auto-discovers existing desc attributes
  -- Use opts.spec (v3 pattern); the v2 API has been removed
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      spec = {
        { "<leader>b", group = "Buffer" },
        { "<leader>f", group = "Format" },
        { "<leader>g", group = "Git" },
        { "<leader>e", group = "Explorer" },
        { "<leader>x", group = "Diagnostics" },
        { "<leader>t", group = "Terminal" },
      },
    },
  },

  -- indent-blankline v3: indent guides + treesitter scope underline
  -- main = "ibl" is REQUIRED — v2 used "indent_blankline" (removed in v3)
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    ---@module "ibl"
    ---@type ibl.config
    opts = {
      scope = {
        enabled = true,
        show_start = true,
        show_end = true,
      },
    },
  },

  -- nvim-autopairs: auto-close brackets and quotes on keystroke
  -- Standalone pattern (no blink.cmp callback) — blink.cmp auto_brackets handles
  -- completion-accepted brackets independently; adding a callback causes double-insert
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {
      check_ts = true,                    -- treesitter-aware: skip pairing inside strings/comments
      enable_check_bracket_line = true,   -- don't pair if closing bracket already on same line
    },
  },
}
