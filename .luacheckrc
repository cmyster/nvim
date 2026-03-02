-- .luacheckrc: luacheck configuration for Neovim config files
-- Suppress undefined global warnings for Neovim runtime globals

-- Declare vim as a known global so luacheck does not warn
-- "undefined global 'vim'" in every Neovim config file.
-- Note: lazydev.nvim handles this for LSP completions; luacheck is a
-- separate static analyzer that needs its own global declaration.
globals = {
  "vim",
}

-- Use LuaJIT standard library (Neovim embeds LuaJIT, not standard Lua 5.x)
std = "luajit"

-- Ignore line length warnings (stylua handles formatting; luacheck should not conflict)
max_line_length = false
