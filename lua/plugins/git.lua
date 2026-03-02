-- GIT-01: gitsigns.nvim v2 API — no 'hl' field in signs table (removed v2.0.0 Jan 2026)
-- GIT-02: toggle_current_line_blame for virtual text blame (NOT blame_line — that opens a popup)
-- GIT-03: vim-fugitive with lazy = false — author explicitly requires this; lazy-loading breaks autocommands
return {
  -- -------------------------------------------------------------------------
  -- gitsigns.nvim: gutter diff signs + inline blame toggle
  -- -------------------------------------------------------------------------
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      signs = {
        add          = { text = "┃" },
        change       = { text = "┃" },
        delete       = { text = "_" },
        topdelete    = { text = "‾" },
        changedelete = { text = "~" },
        untracked    = { text = "┆" },
      },
      signs_staged = {
        add          = { text = "┃" },
        change       = { text = "┃" },
        delete       = { text = "_" },
        topdelete    = { text = "‾" },
        changedelete = { text = "~" },
        untracked    = { text = "┆" },
      },
      signs_staged_enable = true,
      signcolumn  = true,
      numhl       = false,
      linehl      = false,
      word_diff   = false,
      watch_gitdir = { follow_files = true },
      auto_attach = true,
      attach_to_untracked = false,
      current_line_blame = false,           -- off at startup; toggled via <leader>gb
      current_line_blame_opts = {
        virt_text          = true,
        virt_text_pos      = "eol",
        delay              = 1000,
        ignore_whitespace  = false,
        virt_text_priority = 100,
        use_focus          = true,
      },
      current_line_blame_formatter = "<author>, <author_time:%R> - <summary>",
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end
        -- GIT-02: toggle inline blame virtual text (EOL, persistent until toggled off)
        map("n", "<leader>gb", gs.toggle_current_line_blame,
            { desc = "Toggle git blame (virtual text)" })
      end,
    },
  },

  -- -------------------------------------------------------------------------
  -- vim-fugitive: :Git command interface
  -- -------------------------------------------------------------------------
  {
    "tpope/vim-fugitive",
    lazy = false,   -- do NOT lazy-load: registers autocommands and integrations at load time
  },
}
