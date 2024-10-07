return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      local config = require("nvim-treesitter.configs")
      config.setup({
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
        ensure_installed = {
          "bash",
          "c",
          "cmake",
          "cpp",
          "fish",
          "go",
          "gomod",
          "gosum",
          "gotmpl",
          "gowork",
          "lua",
          "luadoc",
          "make",
          "markdown",
          "printf",
          "python",
          "toml",
          "vim",
          "vimdoc",
          "yaml",
        },
      })
    end
  }
}
