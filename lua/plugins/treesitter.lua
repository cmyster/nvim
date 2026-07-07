-- lua/plugins/treesitter.lua
-- nvim-treesitter + nvim-treesitter-textobjects
--
-- MIGRATED master -> main (2026-07-07).
-- The master branch was archived (2025-05-24) and is incompatible with the
-- treesitter core rewrite in Neovim 0.11+/0.12, which produced:
--   treesitter.lua:197: attempt to call method 'range' (a nil value)
-- The main branch is a full, incompatible rewrite:
--   * no more require("nvim-treesitter.configs").setup{...}
--   * parsers installed via require("nvim-treesitter").install{...}  (needs tree-sitter CLI + curl/tar/cc)
--   * highlighting is core Neovim: vim.treesitter.start() per buffer
--   * indentation via vim.bo.indentexpr
--   * incremental_selection was removed -> reimplemented below on the core API
--   * textobjects use require("nvim-treesitter-textobjects").setup{} + select_textobject()
return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,        -- plugin docs: lazy-loading is unsupported
    build = ":TSUpdate", -- keeps installed parsers in sync with the pinned plugin commit
    dependencies = {
      { "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" },
    },
    config = function()
      local ts = require("nvim-treesitter")

      -- Parsers install to install_dir (default: stdpath('data')/site), which the
      -- plugin prepends to runtimepath so freshly built parsers take priority.
      ts.setup({})

      -- Parsers to keep installed. install() is async and a no-op for parsers that
      -- are already present, so it is cheap to call on every startup.
      local ensure = {
        "c", "cpp", "python", "lua", "bash",
        "yaml", "hcl", "json", "rust", "dockerfile",
        "cmake", "make",
      }
      ts.install(ensure)

      -- Highlighting + indentation are enabled per-buffer on the main branch.
      -- vim.treesitter.start() maps the buffer's filetype to a language and errors
      -- if no parser is installed, so pcall keeps unsupported filetypes quiet.
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("user_treesitter_start", { clear = true }),
        callback = function(ev)
          if pcall(vim.treesitter.start, ev.buf) then
            -- Treesitter indentation (experimental upstream, but was enabled before).
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })

      -- ── Incremental selection ────────────────────────────────────────────
      -- Removed from the main branch; reimplemented on Neovim's core treesitter
      -- API to preserve the previous <C-space> / <bs> workflow.
      local incr = {}
      local stack = {}

      local function range_eq(a, b)
        local a1, a2, a3, a4 = a:range()
        local b1, b2, b3, b4 = b:range()
        return a1 == b1 and a2 == b2 and a3 == b3 and a4 == b4
      end

      -- Set a charwise visual selection to a node's range.
      -- range() returns 0-indexed rows and a 0-indexed *exclusive* end column.
      -- We drive it by positioning the cursor rather than the '< '> marks, because
      -- those marks are not authoritative while a visual selection is already active
      -- (they only refresh on leaving visual mode), which made re-selection lag.
      local function visual_select(node)
        local sr, sc, er, ec = node:range()
        local end_col
        if ec == 0 then
          -- node ends at column 0 of a line -> real end is the previous line's EOL
          er = er - 1
          end_col = math.max(vim.fn.col({ er + 1, "$" }) - 2, 0) -- last byte, 0-indexed
        else
          end_col = ec - 1 -- exclusive -> inclusive
        end
        -- Leave any active visual selection so the fresh one starts clean.
        local m = vim.fn.mode()
        if m == "v" or m == "V" or m == "\22" then
          vim.cmd("normal! \27") -- <Esc>
        end
        vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
        vim.cmd("normal! v")
        vim.api.nvim_win_set_cursor(0, { er + 1, end_col })
      end

      function incr.init()
        local node = vim.treesitter.get_node()
        if not node then return end
        stack = { node }
        visual_select(node)
      end

      function incr.increment()
        local node = stack[#stack]
        if not node then return incr.init() end
        local parent = node:parent()
        while parent and range_eq(parent, node) do
          parent = parent:parent()
        end
        if not parent then
          visual_select(node)
          return
        end
        stack[#stack + 1] = parent
        visual_select(parent)
      end

      function incr.decrement()
        if #stack > 1 then stack[#stack] = nil end
        local node = stack[#stack]
        if node then visual_select(node) end
      end

      vim.keymap.set("n", "<C-space>", incr.init,
        { silent = true, desc = "TS: init selection" })
      vim.keymap.set("x", "<C-space>", incr.increment,
        { silent = true, desc = "TS: expand selection to parent node" })
      vim.keymap.set("x", "<bs>", incr.decrement,
        { silent = true, desc = "TS: shrink selection to child node" })

      -- ── Text objects (select) ────────────────────────────────────────────
      require("nvim-treesitter-textobjects").setup({
        select = {
          lookahead = true, -- jump forward to next textobject if cursor not inside one
        },
      })

      local select = require("nvim-treesitter-textobjects.select").select_textobject
      local objects = {
        ["af"] = "@function.outer",  -- function including signature
        ["if"] = "@function.inner",  -- function body only
        ["ac"] = "@class.outer",     -- class including definition line
        ["ic"] = "@class.inner",     -- class body only
        ["aa"] = "@parameter.outer", -- parameter including comma separator
        ["ia"] = "@parameter.inner", -- parameter name/type only
      }
      for lhs, query in pairs(objects) do
        vim.keymap.set({ "x", "o" }, lhs, function()
          select(query, "textobjects")
        end, { silent = true, desc = "TS textobject " .. query })
      end
    end,
  },
}
