-- MUST be first: mapleader before lazy bootstrap or any require
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Load config modules before lazy.setup()
-- Options must be set before plugins initialize (e.g., termguicolors needed by colorscheme)
require("config.options")
require("config.keymaps")
require("config.autocmds")

-- Bootstrap lazy.nvim plugin manager
-- Source: https://lazy.folke.io/installation
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out,                            "WarningMsg" },
      { "\nPress any key to exit...",   "" },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Initialize lazy.nvim
require("lazy").setup({
  spec = {
    { import = "plugins" },  -- auto-discover all files in lua/plugins/
  },
  install = {
    colorscheme = { "tokyonight", "habamax" },  -- use tokyonight during first-run install UI
  },
  checker = { enabled = false },  -- no background update checks
})
