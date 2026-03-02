-- lua/plugins/terminal.lua
-- Toggleable full-width horizontal terminal at bottom ~1/3 of window
-- direction = "horizontal" → spans full editor width (not constrained to a split)
-- size as function → 33% of current window height, recalculates on resize
return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    keys = {
      { "<leader>t", "<cmd>ToggleTerm<CR>", desc = "Toggle terminal" },
    },
    opts = {
      direction = "horizontal",
      -- size as function: 33% of the current Neovim window height
      size = function(term)
        if term.direction == "horizontal" then
          return math.floor(vim.o.lines * 0.33)
        end
        return 80
      end,
      -- open_mapping removed — using keys table above for lazy-load trigger
      shade_terminals = true,
      shading_factor = 2,
      start_in_insert = true,
      persist_size = false, -- always recalculate to 33%
      close_on_exit = true,
    },
  },
}
