-- config/helpscreen.lua
-- Startup help screen showing all keybindings.
-- On startup: auto-closes after 3s or on ESC.
-- On <leader>h toggle: stays open until ESC.

local M = {}

local function build_lines()
	return {
		"",
		"  Neovim Keybindings                    Leader = Space",
		"  ─────────────────────────────────────────────────────",
		"",
		"  GENERAL",
		"    Ctrl+h/j/k/l     Move between splits",
		"    Esc               Clear search highlight",
		"    j / k             Smart movement on wrapped lines",
		"    Esc Esc           Exit terminal mode (in terminal)",
		"",
		"  LEADER SHORTCUTS",
		"    <leader>h         Show this help screen",
		"    <leader>t         Toggle terminal",
		"    <leader>e         Toggle file tree",
		"    <leader>b         Toggle buffers panel",
		"    <leader>f         Format buffer (normal + visual)",
		"    <leader>gb        Toggle git blame (virtual text)",
		"    <leader>xx        Diagnostics panel (Trouble)",
		"    <leader>xX        Buffer diagnostics (Trouble)",
		"",
		"  BUFFER MANAGEMENT",
		"    <leader>bd        Delete buffer",
		"    <leader>bn        Next buffer",
		"    <leader>bp        Previous buffer",
		"",
		"  LSP (active when language server attached)",
		"    gd                Goto definition",
		"    gr                Goto references",
		"    gR                Rename symbol",
		"    gD                Goto declaration",
		"    gi                Goto implementation",
		"    go                Goto type definition",
		"    ga                Code action (normal + visual)",
		"    K                 Hover documentation",
		"",
		"  AI (ghost typing)",
		"    <leader>tg        Toggle ghost typing on/off",
		"    Alt-A             Accept full suggestion",
		"    Alt-a             Accept suggestion (line)",
		"    Alt-e             Dismiss suggestion",
		"",
		"  OTHER",
		"    \\                 Toggle file tree (alt)",
		"",
	}
end

local help_buf = nil
local help_win = nil
local auto_close_timer = nil

local function close_help()
	if auto_close_timer then
		auto_close_timer:stop()
		auto_close_timer:close()
		auto_close_timer = nil
	end
	if help_win and vim.api.nvim_win_is_valid(help_win) then
		vim.api.nvim_win_close(help_win, true)
	end
	if help_buf and vim.api.nvim_buf_is_valid(help_buf) then
		vim.api.nvim_buf_delete(help_buf, { force = true })
	end
	help_win = nil
	help_buf = nil
end

function M.open(auto_close)
	-- If already open, close it (toggle behavior for <leader>h)
	if help_win and vim.api.nvim_win_is_valid(help_win) then
		close_help()
		return
	end

	local lines = build_lines()

	-- Create scratch buffer
	help_buf = vim.api.nvim_create_buf(false, true)
	vim.b[help_buf].display_name = "Welcome"
	vim.api.nvim_buf_set_lines(help_buf, 0, -1, false, lines)
	vim.bo[help_buf].modifiable = false
	vim.bo[help_buf].bufhidden = "wipe"

	-- Calculate centered floating window size
	local width = 57
	local height = 25
	local ui = vim.api.nvim_list_uis()[1]
	local row = math.floor((ui.height - height) / 2)
	local col = math.floor((ui.width - width) / 2)

	help_win = vim.api.nvim_open_win(help_buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
		title = " Welcome ",
		title_pos = "center",
	})

	-- ESC closes the help window
	vim.keymap.set("n", "<Esc>", close_help, { buffer = help_buf, nowait = true })
	-- Also close on q
	vim.keymap.set("n", "q", close_help, { buffer = help_buf, nowait = true })

	if auto_close then
		auto_close_timer = vim.uv.new_timer()
		auto_close_timer:start(7000, 0, vim.schedule_wrap(close_help))
	end
end

-- Setup: map <leader>h and show on startup
function M.setup()
	vim.keymap.set("n", "<leader>h", function()
		M.open(false)
	end, { desc = "Show help screen" })

	-- Show on startup with auto-close, but only when no file arguments given
	vim.api.nvim_create_autocmd("VimEnter", {
		group = vim.api.nvim_create_augroup("helpscreen_startup", { clear = true }),
		callback = function()
			-- Only show when opening nvim with no files (replacing default intro)
			if vim.fn.argc() == 0 then
				-- Name the initial empty buffer so the winbar shows "Welcome"
				vim.api.nvim_buf_set_name(0, "Welcome")
				-- Defer so the UI is fully drawn
				vim.defer_fn(function()
					M.open(true)
				end, 50)
			end
		end,
	})
end

return M
