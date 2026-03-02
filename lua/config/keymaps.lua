local map = vim.keymap.set

-- Window navigation (Ctrl+hjkl)
map("n", "<C-h>", "<C-w>h", { desc = "Move to left split" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to below split" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to above split" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right split" })

-- Terminal mode escape
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Better j/k on wrapped lines (conventional even with wrap=false)
map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- Clear search highlight with Escape
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Buffer management (<leader>b prefix — established in CONTEXT.md)
map("n", "<leader>bd", "<cmd>bdelete<CR>",   { desc = "Delete buffer" })
map("n", "<leader>bn", "<cmd>bnext<CR>",     { desc = "Next buffer" })
map("n", "<leader>bp", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
