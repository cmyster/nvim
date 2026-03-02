-- neo-tree.nvim: file tree with git status, buffers panel, and devicons
-- Branch v3.x — use `:Neotree toggle` not NeoTreeToggle (v2 compat shim only)
-- Dependencies already declared in deps.lua; listed here for load-order guarantee only
return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<cr>",                desc = "Toggle file tree" },
      { "\\",        "<cmd>Neotree toggle<cr>",                desc = "Toggle file tree (alt)" },
      { "<leader>b", "<cmd>Neotree source=buffers toggle<cr>", desc = "Toggle buffers panel" },
    },
    opts = {
      close_if_last_window = true,
      window = {
        position = "left",
        width = 35,
      },
      filesystem = {
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,
        filtered_items = {
          hide_dotfiles = false,
          hide_gitignored = false,
        },
      },
      buffers = {
        follow_current_file = { enabled = true },
        show_unloaded = true,
      },
      git_status = {
        window = { position = "float" },
      },
    },
  },
}
