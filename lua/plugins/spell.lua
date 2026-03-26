-- lua/plugins/spell.lua
-- Auto-popup aspell suggestions when cursor lands on a misspelled word.
-- Select a suggestion with Enter to replace; dismiss with q/Esc.

return {
  {
    dir = vim.fn.stdpath("config"),
    name = "spell-suggest",
    event = "VeryLazy",
    config = function()
      if vim.fn.executable("aspell") ~= 1 then
        return
      end

      local popup_win = nil
      local popup_buf = nil

      local function close_popup()
        if popup_win and vim.api.nvim_win_is_valid(popup_win) then
          vim.api.nvim_win_close(popup_win, true)
        end
        popup_win = nil
        popup_buf = nil
      end

      local function show_suggestions()
        close_popup()

        local word = vim.fn.expand("<cword>")
        if word == "" or not word:match("%a") then
          return
        end

        -- Check if word is actually misspelled (via neovim's spell checking)
        local bad = vim.fn.spellbadword(word)
        if bad[1] == "" then
          return
        end
        local spell_type = bad[2] -- "bad", "cap", or "rare"

        -- Save cursor context
        local orig_buf = vim.api.nvim_get_current_buf()
        local orig_pos = vim.api.nvim_win_get_cursor(0)
        local orig_row = orig_pos[1]
        local orig_col = orig_pos[2]
        local orig_line = vim.api.nvim_buf_get_lines(orig_buf, orig_row - 1, orig_row, false)[1]

        local suggestions = {}

        if spell_type == "cap" then
          -- Capitalization error: offer capitalized version
          table.insert(suggestions, word:sub(1, 1):upper() .. word:sub(2))
        else
          -- Spelling error: run aspell in pipe mode
          local raw = vim.fn.system("echo " .. vim.fn.shellescape(word) .. " | aspell -a")
          for line in raw:gmatch("[^\n]+") do
            if line:match("^&") then
              local after_colon = line:match(": (.+)$")
              if after_colon then
                for sug in after_colon:gmatch("[^,]+") do
                  sug = vim.trim(sug)
                  table.insert(suggestions, sug)
                  if #suggestions >= 3 then break end
                end
              end
            end
          end
        end

        if #suggestions == 0 then
          return
        end

        -- Build popup content (no numbering)
        local max_w = 0
        for _, s in ipairs(suggestions) do
          max_w = math.max(max_w, #s)
        end

        popup_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(popup_buf, 0, -1, false, suggestions)
        vim.bo[popup_buf].bufhidden = "wipe"
        vim.bo[popup_buf].modifiable = false
        vim.bo[popup_buf].buftype = "nofile"

        popup_win = vim.api.nvim_open_win(popup_buf, true, {
          relative = "cursor",
          row = 1,
          col = 0,
          width = max_w + 2,
          height = #suggestions,
          style = "minimal",
          border = "rounded",
        })

        -- Place cursor on first suggestion
        vim.api.nvim_win_set_cursor(popup_win, { 1, 0 })

        -- Find word start position in original line (0-indexed)
        local function find_word_start()
          local search_start = math.max(1, orig_col - #word + 2)
          local start_col = orig_line:find(word, search_start, true)
          if start_col then
            return start_col - 1
          end
          start_col = orig_line:find(word, 1, true)
          if start_col then
            return start_col - 1
          end
          return nil
        end

        -- Select current line as replacement
        local function pick_current()
          local cursor = vim.api.nvim_win_get_cursor(popup_win)
          local replacement = suggestions[cursor[1]]
          close_popup()
          if replacement then
            local start_col = find_word_start()
            if start_col then
              vim.api.nvim_buf_set_text(
                orig_buf,
                orig_row - 1, start_col,
                orig_row - 1, start_col + #word,
                { replacement }
              )
            end
          end
        end

        -- Keymaps: Enter to pick, j/k to navigate, q/Esc to dismiss
        vim.keymap.set("n", "<CR>", pick_current, { buffer = popup_buf, nowait = true })
        vim.keymap.set("n", "q", close_popup, { buffer = popup_buf, nowait = true })
        vim.keymap.set("n", "<Esc>", close_popup, { buffer = popup_buf, nowait = true })

        vim.api.nvim_create_autocmd("BufLeave", {
          buffer = popup_buf,
          once = true,
          callback = close_popup,
        })
      end

      -- Auto-show suggestions when cursor holds on a misspelled word
      local timer = nil
      vim.api.nvim_create_autocmd("CursorHold", {
        callback = function()
          if popup_win then return end
          if not vim.wo.spell then return end
          if timer then
            timer:stop()
            timer = nil
          end
          -- Only trigger in normal mode for regular buffers
          if vim.fn.mode() ~= "n" then return end
          if vim.bo.buftype ~= "" then return end
          show_suggestions()
        end,
      })

      -- Close popup when cursor moves
      vim.api.nvim_create_autocmd("CursorMoved", {
        callback = function()
          -- Only close if we're NOT in the popup buffer
          if popup_buf and vim.api.nvim_get_current_buf() == popup_buf then
            return
          end
          close_popup()
        end,
      })
    end,
  },
}
