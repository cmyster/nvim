-- lua/plugins/ghosttype.lua
-- AI ghost-text completions via minuet-ai.nvim
--
-- Provider hierarchy:
--   1. LOCAL: AMD ROCm gfx1100 GPU + llama-server + Qwen2.5-Coder-32B model
--   2. CLAUDE CODE: ANTHROPIC_API_KEY (Claude Haiku) if local is unavailable
--   3. NONE: plugin disabled if both are unavailable
--
-- Toggle auto-trigger on/off: <leader>tg

local LLAMA_PORT = 8012
local MODEL_PATH = "~/.fakeoid/models/Qwen2.5-Coder-32B-Instruct-Q4_K_M.gguf"

local function local_available()
  if vim.fn.executable("llama-server") ~= 1 then return false end
  if vim.fn.executable("rocminfo") ~= 1 then return false end
  local rocm_out = vim.fn.system("rocminfo 2>/dev/null | grep -c gfx1100")
  if tonumber(vim.trim(rocm_out)) == 0 then return false end
  return vim.fn.filereadable(vim.fn.expand(MODEL_PATH)) == 1
end

local function claude_available()
  local ak = vim.fn.getenv("ANTHROPIC_API_KEY")
  return ak ~= vim.NIL and ak ~= ""
end

local function is_port_in_use(port)
  local r = vim.fn.system("ss -tln sport = :" .. port .. " 2>/dev/null | grep -c LISTEN")
  return tonumber(vim.trim(r)) > 0
end

return {
  {
    "milanglacier/minuet-ai.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cond = function()
      return local_available() or claude_available()
    end,
    config = function()
      local cfg = {
        throttle = 1000,
        debounce = 400,
        n_completions = 1,
        virtualtext = {
          auto_trigger_ft = {},  -- empty = all filetypes
          keymap = {
            accept      = "<A-A>",  -- accept full suggestion
            accept_line = "<A-a>",  -- accept single line
            prev        = "<A-[>",  -- previous suggestion
            next        = "<A-]>",  -- next suggestion
            dismiss     = "<A-e>",  -- dismiss
          },
        },
      }

      if local_available() then
        cfg.request_timeout = 3
        cfg.provider = "openai_fim_compatible"
        cfg.provider_options = {
          openai_fim_compatible = {
            api_key   = "NONE",
            end_point = "http://127.0.0.1:" .. LLAMA_PORT .. "/v1/completions",
            model     = "qwen2.5-coder",
            name      = "llama-server",
            optional  = { max_tokens = 128, top_p = 0.9, temperature = 0.2 },
          },
        }

        local server_job = nil
        if not is_port_in_use(LLAMA_PORT) then
          server_job = vim.fn.jobstart({
            "llama-server", "--model", vim.fn.expand(MODEL_PATH),
            "--port", tostring(LLAMA_PORT), "-ngl", "99",
            "--flash-attn", "on", "-ub", "1024", "-b", "1024",
            "--ctx-size", "4096", "--cache-reuse", "256",
          }, {
            on_exit = function(_, code)
              if code ~= 0 then
                vim.schedule(function()
                  vim.notify("llama-server exited (code " .. code .. ")", vim.log.levels.WARN)
                end)
              end
              server_job = nil
            end,
          })
          if server_job <= 0 then
            vim.notify("Failed to start llama-server (jobstart=" .. server_job .. ")", vim.log.levels.ERROR)
            server_job = nil
          end
        end

        vim.api.nvim_create_autocmd("VimLeavePre", {
          callback = function()
            if server_job then vim.fn.jobstop(server_job) end
          end,
        })

      else  -- claude code
        cfg.request_timeout = 8
        cfg.provider = "claude"
        cfg.provider_options = {
          claude = {
            api_key    = "ANTHROPIC_API_KEY",
            model      = "claude-haiku-4-5-20251001",
            max_tokens = 256,
            optional   = { temperature = 0.2 },
          },
        }
      end

      require("minuet").setup(cfg)

      vim.g.minuet_ghost_enabled = true

      vim.keymap.set("n", "<leader>tg", function()
        vim.cmd("Minuet virtualtext toggle")
        vim.g.minuet_ghost_enabled = not vim.g.minuet_ghost_enabled
        vim.notify("Ghost typing: " .. (vim.g.minuet_ghost_enabled and "ON" or "OFF"), vim.log.levels.INFO)
      end, { desc = "Toggle ghost typing" })
    end,
  },
}
