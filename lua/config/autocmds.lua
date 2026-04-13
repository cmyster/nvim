-- 1. Highlight on yank (Neovim 0.11+ uses vim.hl.on_yank)
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
  desc = "Highlight yanked text",
  callback = function()
    vim.hl.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

-- 2. Restore cursor position on file open
vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("restore_cursor", { clear = true }),
  desc = "Restore cursor position when opening a file",
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- 3. Strip trailing whitespace on save (winsaveview/winrestview prevents cursor jump)
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("strip_whitespace", { clear = true }),
  pattern = "*",
  desc = "Remove trailing whitespace on save",
  callback = function()
    local view = vim.fn.winsaveview()
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})

-- 4. Set conceallevel for JSON files (show quote characters)
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("json_conceal", { clear = true }),
  pattern = { "json", "jsonc" },
  desc = "Set conceallevel=0 for JSON files to show quote characters",
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
})

-- 5. Enable spell checking for git commit messages
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("gitcommit_spell", { clear = true }),
  pattern = "gitcommit",
  desc = "Enable spell checking for git commit messages",
  callback = function()
    vim.opt_local.spell = true
  end,
})

-- 6. Per-language indentation overrides (4 spaces for Python and Rust)
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("filetype_indent", { clear = true }),
  pattern = { "python", "rust" },
  desc = "Use 4-space indentation for Python and Rust",
  callback = function()
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4
  end,
})
