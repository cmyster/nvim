return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("tokyonight").setup({
        style = "night",         -- darkest variant, highest contrast
        transparent = false,     -- off by default for terminal compatibility
        terminal_colors = true,  -- also set terminal ANSI colors
      })
      vim.cmd.colorscheme("tokyonight-night")
    end,
  },
}
