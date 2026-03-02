-- lua/plugins/lsp.lua
-- mason.nvim + mason-lspconfig v2 + nvim-lspconfig + SchemaStore
--
-- API notes (mason-lspconfig v2 + Neovim 0.11):
-- - NO setup_handlers: use vim.lsp.config() + automatic_enable = true
-- - vim.lsp.config() calls go BEFORE require("mason-lspconfig").setup()
-- - blink.cmp must load before lspconfig (declared in dependencies)
-- - rust_analyzer: if `which rust-analyzer` finds one on PATH via rustup,
--   add: automatic_enable = { exclude = { "rust_analyzer" } }
--   and manage via rustup instead of mason to avoid duplicate servers.
--   Check: :LspInfo should show exactly one rust_analyzer client.

-- ---------------------------------------------------------------------------
-- Section 1: Diagnostic configuration (LSP-04)
-- Runs immediately at file load time (before return statement).
-- ---------------------------------------------------------------------------
vim.diagnostic.config({
	severity_sort = true,
	update_in_insert = false,
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "E",
			[vim.diagnostic.severity.WARN] = "W",
			[vim.diagnostic.severity.INFO] = "I",
			[vim.diagnostic.severity.HINT] = "H",
		},
	},
	virtual_text = false, -- no inline text; float shows on cursor hover
	float = {
		border = "rounded",
		source = "if_many",
	},
})

-- Show diagnostic float automatically when cursor rests on a diagnostic sign
vim.api.nvim_create_autocmd("CursorHold", {
	group = vim.api.nvim_create_augroup("project-diag-float", { clear = true }),
	callback = function()
		vim.diagnostic.open_float(nil, { focus = false })
	end,
})

-- ---------------------------------------------------------------------------
-- Section 2: LspAttach autocmd — buffer-scoped keymaps (LSP-03)
-- Named augroup with clear=true for safe config reload.
-- All keymaps must use buffer = event.buf (not global).
-- ---------------------------------------------------------------------------
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("project-lsp-attach", { clear = true }),
	callback = function(event)
		local map = function(keys, func, desc, mode)
			mode = mode or "n"
			vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
		end

		-- Required keymaps (LSP-03): these are NOT 0.11 defaults — map all explicitly
		map("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
		map("gr", vim.lsp.buf.references, "[G]oto [R]eferences")
		map("K", vim.lsp.buf.hover, "[K] Hover Documentation")
		map("gR", vim.lsp.buf.rename, "[R]ename Symbol")
		-- ga with visual mode support (code actions work on selection)
		vim.keymap.set(
			{ "n", "v" },
			"ga",
			vim.lsp.buf.code_action,
			{ buffer = event.buf, desc = "LSP: [G]oto Code [A]ction" }
		)
		map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
		map("gi", vim.lsp.buf.implementation, "[G]oto [I]mplementation")
		map("go", vim.lsp.buf.type_definition, "[G]oto Type Definition")
	end,
})

-- ---------------------------------------------------------------------------
-- Section 3: Plugin specs
-- ---------------------------------------------------------------------------
return {
	-- SchemaStore.nvim: provides JSON and YAML schema catalogues
	-- lazy = true: loaded on demand inside mason-lspconfig config function
	{ "b0o/SchemaStore.nvim", lazy = true },

	-- mason-lspconfig v2: manages server installation and automatic LSP enable
	{
		"mason-org/mason-lspconfig.nvim",
		dependencies = {
			-- mason.nvim: the underlying server installer (opts = {} triggers setup)
			{ "mason-org/mason.nvim", opts = {} },
			-- nvim-lspconfig: server configuration defaults
			"neovim/nvim-lspconfig",
			-- CRITICAL: blink.cmp must patch vim.lsp.config['*'].capabilities
			-- before any server starts. This dependency forces blink.cmp to load first.
			"saghen/blink.cmp",
		},
		opts = {
			ensure_installed = {
				"clangd", -- C/C++ (LSP-02)
				"pyright", -- Python
				"lua_ls", -- Lua
				"bashls", -- Bash
				"yamlls", -- YAML (SchemaStore integration)
				"dockerls", -- Dockerfile
				"terraformls", -- Terraform (NOT terraform_lsp — see STATE.md)
				"jsonls", -- JSON (SchemaStore integration)
				"rust_analyzer", -- Rust
			},
			-- automatic_enable: calls vim.lsp.enable(name) for each installed server
			-- Per-server settings are provided via vim.lsp.config() calls below
			automatic_enable = true,
		},
		config = function(_, opts)
			-- Per-server vim.lsp.config() calls for servers with custom settings (LSP-05, LSP-02)
			-- These MUST run before require("mason-lspconfig").setup() so automatic_enable
			-- picks up the custom settings when it calls vim.lsp.enable().

			-- yamlls: SchemaStore integration (LSP-05)
			-- REQUIRED: disable built-in schemaStore to avoid conflict with SchemaStore.nvim
			vim.lsp.config("yamlls", {
				settings = {
					yaml = {
						schemaStore = {
							enable = false, -- REQUIRED: prevents built-in schema fetching
							url = "", -- REQUIRED: prevents TypeError on empty url
						},
						schemas = require("schemastore").yaml.schemas(),
					},
				},
			})

			-- jsonls: SchemaStore integration (LSP-05)
			vim.lsp.config("jsonls", {
				settings = {
					json = {
						schemas = require("schemastore").json.schemas(),
						validate = { enable = true },
					},
				},
			})

			-- lua_ls: Neovim runtime context
			-- library: inject VIMRUNTIME so lua-ls knows vim.* types directly.
			-- lazydev adds completions on top; this is the reliable fallback.
			vim.lsp.config("lua_ls", {
				settings = {
					Lua = {
						runtime = { version = "LuaJIT" },
						workspace = {
							checkThirdParty = false,
							library = { vim.env.VIMRUNTIME },
						},
					},
				},
			})

			-- Run mason-lspconfig setup with the opts table
			require("mason-lspconfig").setup(opts)
		end,
	},
}
