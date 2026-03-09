-- lua/plugins/linting.lua
-- mason-tool-installer + nvim-lint
--
-- Two specs returned:
--   1. mason-tool-installer: auto-installs ALL formatter + linter binaries on first launch
--   2. nvim-lint: async per-filetype linting with diagnostics alongside LSP

return {
  -- ---------------------------------------------------------------------------
  -- Spec 1: mason-tool-installer
  -- Installs all formatter and linter binaries through Mason.
  -- Uses opts style (table-only) because ensure_installed is a plain list.
  -- mason.nvim is already installed by Phase 3 (lsp.lua); lazy.nvim deduplicates.
  -- ---------------------------------------------------------------------------
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = {
      -- mason.nvim: already installed by Phase 3 lsp.lua; lazy.nvim deduplicates
      { "mason-org/mason.nvim", opts = {} },
    },
    opts = {
      ensure_installed = {
        -- Formatters (used by conform.nvim from formatting.lua)
        "clang-format",   -- C/C++: uses hyphen (conform v9 renamed from clang_format)
        "ruff",           -- Python: dual-use binary (ruff_fix + ruff_format + ruff_organize_imports for conform; ruff check for nvim-lint)
        "stylua",         -- Lua
        "shfmt",          -- Bash/sh: handles both sh and bash filetypes
        "prettier",       -- YAML, JSON

        -- rustfmt NOT listed: deprecated in Mason registry; managed by rustup.
        -- conform.nvim finds rustfmt via PATH automatically (installed with Rust toolchain).

        -- terraform NOT listed: terraform fmt uses the terraform binary itself,
        -- which is already installed by mason-lspconfig as part of terraformls (Phase 3).
        -- Adding it here would create a duplicate Mason package conflict.

        -- Linters (used by nvim-lint)
        "cpplint",        -- C/C++
        "luacheck",       -- Lua: reads .luacheckrc for Neovim global suppression
        "shellcheck",     -- Bash/sh: handles both bash and sh filetypes
        "yamllint",       -- YAML
        "hadolint",       -- Dockerfile
        "tflint",         -- Terraform
        "jsonlint",       -- JSON

        -- ruff linter NOT listed separately: "ruff" above is the same binary
        -- No Rust linter: rust_analyzer LSP provides all Rust diagnostics
      },
    },
  },

  -- ---------------------------------------------------------------------------
  -- Spec 2: nvim-lint
  -- Async linter that produces diagnostics alongside (not replacing) LSP diagnostics.
  -- Uses config function (NOT opts): linters_by_ft assignment and autocmd creation
  -- cannot be expressed as a plain opts table — this is the one exception to the
  -- opts-style preference used elsewhere in this config.
  --
  -- event list MUST match autocmd events exactly: lazy.nvim only loads the plugin
  -- when one of these events fires, so the plugin is not available before BufReadPost.
  -- ---------------------------------------------------------------------------
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufWritePost" },  -- matches autocmd events exactly
    config = function()
      local lint = require("lint")

      -- Map filetypes to linter(s).
      -- sh and bash are BOTH mapped to shellcheck:
      --   - Neovim assigns "sh" filetype to .sh files without a #!/bin/bash shebang
      --   - Neovim assigns "bash" filetype to files with a #!/bin/bash shebang
      --   Both need shellcheck coverage.
      -- No Rust entry: rust_analyzer LSP provides all Rust diagnostics via vim.lsp.
      -- Override yamllint args to use config from this nvim directory.
      -- Default max line-length is 80; our config sets it to 120 to match colorcolumn.
      lint.linters.yamllint.args = {
        "-c", vim.fn.stdpath("config") .. "/.yamllint.yaml",
        "-f", "parsable",
        "-",
      }

      lint.linters_by_ft = {
        c          = { "cpplint" },
        cpp        = { "cpplint" },
        python     = { "ruff" },
        lua        = { "luacheck" },
        sh         = { "shellcheck" },   -- .sh files without #!/bin/bash shebang
        bash       = { "shellcheck" },   -- files with #!/bin/bash shebang
        yaml       = { "yamllint" },
        dockerfile = { "hadolint" },     -- Neovim filetype string is "dockerfile" (lowercase)
        terraform  = { "tflint" },
        json       = { "jsonlint" },
      }

      -- Named augroup with clear=true: prevents duplicate autocmds on :source or :Lazy reload.
      -- Pattern matches Phase 3 lsp.lua (project-lsp-attach augroup) and options.lua.
      vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
        group = vim.api.nvim_create_augroup("project-lint", { clear = true }),
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  },
}
