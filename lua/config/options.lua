local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Indentation (global defaults — 2 spaces for Lua/YAML/JSON/etc)
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true

-- Editor feel
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.cursorline = true
opt.colorcolumn = "80"
opt.signcolumn = "yes"
opt.wrap = false

-- Clipboard and mouse
opt.clipboard = "unnamedplus"
opt.mouse = "a"

-- File handling
opt.undofile = true
opt.swapfile = false

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false
opt.incsearch = true

-- Timing
opt.updatetime = 250
opt.timeoutlen = 300

-- Splits
opt.splitright = true
opt.splitbelow = true

-- Terminal colors
opt.termguicolors = true
