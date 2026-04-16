-- lua/plugins/statusline.lua
-- SL-01: lualine.nvim statusline — mode, filename+modified, filetype, progress, location
-- SL-02: git branch + diff stats from gitsigns v2 via vim.b.gitsigns_status_dict
-- SL-03: active LSP server name via lualine built-in lsp_status component
-- SL-04: winbar breadcrumbs via nvim-navic (LSP-backed function/class context)

-- diff_source: reads gitsigns v2 buffer-local dict for added/changed/removed counts
-- CRITICAL: gitsigns uses "changed"; lualine diff component expects "modified" — rename required
-- Source: https://github.com/nvim-lualine/lualine.nvim/wiki/Component-snippets
local function diff_source()
  local gitsigns = vim.b.gitsigns_status_dict
  if gitsigns then
    return {
      added    = gitsigns.added,
      modified = gitsigns.changed,  -- gitsigns key is "changed"; lualine expects "modified"
      removed  = gitsigns.removed,
    }
  end
end

return {
  -- ---------------------------------------------------------------------------
  -- nvim-navic: LSP breadcrumb provider for winbar (SL-04)
  -- auto_attach = true: hooks into LspAttach internally — do NOT call navic.attach()
  -- in lsp.lua; that causes double-attach errors.
  -- Source: https://raw.githubusercontent.com/SmiteshP/nvim-navic/master/README.md
  -- ---------------------------------------------------------------------------
  {
    "SmiteshP/nvim-navic",
    dependencies = { "neovim/nvim-lspconfig" },
    opts = {
      lsp = {
        auto_attach = true,
      },
      highlight   = true,   -- use NavicIcons* highlight groups (colored icons)
      separator   = " > ",  -- breadcrumb separator between scope levels
      depth_limit = 5,      -- avoid very deep nesting cluttering the winbar
    },
  },

  -- ---------------------------------------------------------------------------
  -- lualine.nvim: statusline engine (SL-01, SL-02, SL-03) + winbar (SL-04)
  -- dependencies: nvim-web-devicons already in deps.lua; nvim-navic loaded above
  -- globalstatus = true: single statusline bar across all splits (laststatus=3)
  -- DO NOT set vim.o.laststatus manually in options.lua — lualine handles it
  -- Source: https://raw.githubusercontent.com/nvim-lualine/lualine.nvim/master/README.md
  -- ---------------------------------------------------------------------------
  {
    "nvim-lualine/lualine.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "SmiteshP/nvim-navic",   -- winbar breadcrumbs must load before lualine registers winbar
    },
    opts = {
      options = {
        theme                = "tokyonight",  -- matches project colorscheme (Phase 1)
        globalstatus         = true,          -- single statusline for all windows
        icons_enabled        = true,
        component_separators = { left = "", right = "" },
        section_separators   = { left = "", right = "" },
        disabled_filetypes   = {
          statusline = { "neo-tree" },  -- suppress in file tree window (Phase 5)
          winbar     = { "neo-tree" },
        },
      },
      sections = {
        lualine_a = { "mode" },                                    -- SL-01: current mode
        lualine_b = {
          "branch",                                                -- SL-02: git branch (native git query)
          { "diff", source = diff_source },                        -- SL-02: gitsigns v2 diff stats
          "diagnostics",                                           -- SL-04 (diag counts; E/W/I/H)
        },
        lualine_c = {
          {
            function()                                                     -- SL-01 custom filename
              local ft = vim.bo.filetype
              if ft == "neo-tree"   then return "Tree"     end
              if ft == "toggleterm" then return "Terminal" end
              if vim.b.display_name then return vim.b.display_name end
              local bufname = vim.api.nvim_buf_get_name(0)
              if bufname == "Welcome" then return "Welcome" end
              if bufname == "Spell"   then return "Spell"   end
              local filename = vim.fn.expand("%:t")
              if filename == "" then return "[No Name]" end
              local modified = vim.bo.modified and " [+]" or ""
              local readonly  = (vim.bo.readonly or not vim.bo.modifiable) and " [-]" or ""
              return filename .. modified .. readonly
            end,
          },
        },
        lualine_x = {
          { "lsp_status", show_name = true, ignore_lsp = {} },    -- SL-03: active LSP server name
          "filetype",                                              -- SL-01: filetype with icon
        },
        lualine_y = { "progress" },   -- SL-01: cursor percentage through file
        lualine_z = { "location" },   -- SL-01: line:column
      },
      inactive_sections = {
        lualine_c = { "filename" },
        lualine_x = { "location" },
      },
      winbar = {
        lualine_c = {
          {
            function()
              local navic = require("nvim-navic")
              if navic.is_available() then
                local location = navic.get_location()
                if location ~= "" then
                  return location
                end
              end
              return " "  -- keep winbar visible (empty space) to prevent content jumping
            end,
          },
        },
      },
      inactive_winbar = {
        lualine_c = {
          {
            function()
              if vim.w.float_overlay    then return vim.w.float_overlay    end
              if vim.g.active_sidebar   then return vim.g.active_sidebar   end
              return vim.fn.expand("%:t")
            end,
            color = { fg = "grey" },
          },
        },
      },
    },
  },
}
