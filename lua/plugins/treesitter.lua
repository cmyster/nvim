-- lua/plugins/treesitter.lua
-- nvim-treesitter + nvim-treesitter-textobjects
-- CRITICAL: Both plugins pinned to branch = "master".
-- The main branch permanently removed incremental_selection and ensure_installed.
-- Do NOT change branches without understanding the API differences.
return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    lazy = false,        -- plugin docs: lazy-loading is unsupported
    build = ":TSUpdate", -- compiles parsers from C source via Neovim build system
    dependencies = {
      -- textobjects pinned to master to match configs.setup() integration API
      { "nvim-treesitter/nvim-treesitter-textobjects", branch = "master" },
    },
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          -- original 10 from requirements
          "c", "cpp", "python", "lua", "bash",
          "yaml", "hcl", "json", "rust", "dockerfile",
          -- user-added 2 (cmake and make confirmed in master branch parser registry)
          "cmake", "make",
        },
        sync_install = false,  -- async install; don't block startup
        auto_install = false,  -- explicit list only; no on-demand surprises

        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false, -- avoid double-parsing slowdown
        },

        indent = {
          enable = true,
        },

        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection    = "<C-space>", -- normal mode: start selection at cursor node
            node_incremental  = "<C-space>", -- visual mode: expand selection to parent node
            scope_incremental = false,       -- not used
            node_decremental  = "<bs>",      -- visual mode: shrink selection to child node
          },
        },

        -- textobjects configured here, NOT via require("nvim-treesitter-textobjects").setup()
        -- that call is the main branch API and is incompatible with master
        textobjects = {
          select = {
            enable = true,
            lookahead = true, -- jump forward to next textobject if cursor not inside one
            keymaps = {
              ["af"] = "@function.outer", -- function including signature
              ["if"] = "@function.inner", -- function body only
              ["ac"] = "@class.outer",    -- class including definition line
              ["ic"] = "@class.inner",    -- class body only
              ["aa"] = "@parameter.outer", -- parameter including comma separator
              ["ia"] = "@parameter.inner", -- parameter name/type only
            },
          },
        },
      })
    end,
  },
}
