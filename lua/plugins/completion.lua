-- lua/plugins/completion.lua
-- blink.cmp completion engine + friendly-snippets + lazydev Lua API source
-- LOAD ORDER: This file must be processed by lazy.nvim BEFORE nvim-lspconfig.
-- In lsp.lua, declare "saghen/blink.cmp" as a dependency of nvim-lspconfig
-- to guarantee blink.cmp patches vim.lsp.config['*'].capabilities first.
return {
  -- lazydev.nvim: Neovim-API-aware Lua LSP completion (vim.api, vim.fn, vim.uv)
  -- Loaded only for Lua files (ft = "lua") — no startup cost for other filetypes.
  -- Place BEFORE blink.cmp so sources.providers.lazydev can reference it.
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      -- Always enable: config dir is symlinked so lazydev's path-matching fails
      enabled = function()
        return true
      end,
      library = {
        -- Provide uv (libuv) type hints for vim.uv.* calls
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },

  -- blink.cmp: completion engine with native Rust fuzzy matching
  -- version = "1.*" uses tagged releases with pre-built Rust binaries (no Rust toolchain needed)
  -- opts style (not config function) is required for opts_extend to work across plugins
  {
    "saghen/blink.cmp",
    dependencies = {
      -- friendly-snippets: VSCode-compatible snippet library for 40+ languages
      -- auto-loaded by the blink.cmp snippets source when present
      "rafamadriz/friendly-snippets",
    },
    version = "1.*",
    opts = {
      -- Keymap preset: Tab/S-Tab navigate items, Enter accepts, Tab also expands snippets
      -- <Right> accepts the current suggestion (or ghost text word) — like VSCode/Copilot feel
      keymap = {
        preset = "default",
        ["<Right>"] = { "accept", "fallback" },
      },

      -- Appearance: use mono nerd font variant for icons
      appearance = { nerd_font_variant = "mono" },

      -- Sources: lazydev first (Lua files), then standard LSP/path/snippets/buffer
      sources = {
        default = { "lazydev", "lsp", "path", "snippets", "buffer" },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100, -- prioritize lazydev over LSP for Lua files
          },
        },
      },

      -- Completion popup: show documentation automatically after 500ms delay
      -- Ghost text: show inline preview of top-ranked completion item
      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 500 },
        ghost_text = { enabled = true },
      },

      -- Cmdline completion for : command mode and / search mode (CMP-04)
      cmdline = {
        keymap = { preset = "inherit" },
        completion = { menu = { auto_show = true } },
      },

      -- Fuzzy: use Rust implementation for performance; warn if falling back to Lua
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },

    -- opts_extend: allows other plugin specs (lsp.lua, future phases) to append sources
    opts_extend = { "sources.default" },
  },
}
