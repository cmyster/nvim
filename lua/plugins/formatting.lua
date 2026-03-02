-- lua/plugins/formatting.lua
-- conform.nvim: format-on-save + manual <leader>f keymap (normal + visual range)
-- Uses opts style (not config function) to match project pattern (see completion.lua)
-- and to allow lazy.nvim opts merging by other plugin specs if needed.
return {
  {
    "stevearc/conform.nvim",

    -- Lazy-load on BufWritePre so conform is available the first time a buffer is saved.
    -- format_on_save fires on this same event internally — no separate autocmd needed.
    event = { "BufWritePre" },

    -- Also load when user runs :ConformInfo to inspect formatter status.
    cmd = { "ConformInfo" },

    keys = {
      {
        "<leader>f",
        function()
          require("conform").format({ async = true })
        end,
        -- mode = "" covers Normal, Visual, Select, and Operator-pending modes.
        -- conform detects an active visual selection automatically and formats
        -- only that range — no separate visual-mode mapping needed.
        mode = "",
        desc = "Format buffer",
      },
    },

    opts = {
      -- formatters_by_ft: maps Neovim filetype → list of conform formatter names.
      -- Wrong names cause silent failures (conform skips unknown formatters).
      -- All names here are from conform.nvim v9 built-in formatter list.
      formatters_by_ft = {
        -- clang-format: uses hyphen (NOT clang_format with underscore).
        -- conform.nvim v9 renamed the built-in from clang_format to clang-format.
        c   = { "clang-format" },
        cpp = { "clang-format" },

        -- Python: three-step ruff chain.
        --   ruff_fix            → runs `ruff check --fix` (lint auto-fixes)
        --   ruff_format         → runs `ruff format`      (code style / black-compatible)
        --   ruff_organize_imports → runs `ruff check --select I --fix` (isort-compatible)
        -- Using only "ruff" would run check --fix only, skipping formatting and import sorting.
        python = { "ruff_fix", "ruff_format", "ruff_organize_imports" },

        lua = { "stylua" },

        -- Neovim assigns the "sh" filetype to .sh files that do not contain a #!/bin/bash
        -- shebang. Files with #!/bin/bash get filetype "bash". Both need shfmt.
        sh   = { "shfmt" },
        bash = { "shfmt" },

        yaml      = { "prettier" },
        json      = { "prettier" },

        -- terraform_fmt (underscore): conform.nvim's built-in name for `terraform fmt`.
        -- There is no separate terraform-fmt binary — conform calls the terraform binary
        -- with the fmt subcommand. The name uses underscore, matching conform's convention.
        terraform = { "terraform_fmt" },

        rust = { "rustfmt" },
      },

      -- default_format_opts applies when format() is called without explicit options.
      -- lsp_format = "fallback": use the LSP formatter only when no conform formatter
      -- is configured for the current filetype. NOT "lsp_fallback" — that key was
      -- removed in conform.nvim v9.0.0 and will silently do nothing if used.
      default_format_opts = {
        lsp_format = "fallback",
      },

      -- format_on_save: conform hooks into BufWritePre automatically when this table
      -- is present. Do NOT add a manual BufWritePre autocmd — that would double-format.
      format_on_save = {
        timeout_ms = 500,
        -- Same fallback behaviour as default_format_opts: LSP only when no formatter.
        lsp_format  = "fallback",
      },
    },
  },
}
