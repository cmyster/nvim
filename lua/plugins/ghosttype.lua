-- lua/plugins/ghosttype.lua
-- AI ghost-text completions via local llama-server + minuet-ai.nvim
--
-- Provides Copilot-style inline code suggestions powered entirely by local hardware.
-- Uses Qwen2.5-Coder-32B on AMD 7900XTX via ROCm with FIM (fill-in-middle) completions.
--
-- Conditional loading: this plugin only loads when ALL prerequisites are present:
--   1. llama-server binary available
--   2. rocminfo binary available
--   3. gfx1100 GPU detected by rocminfo
--   4. Model file exists at ~/.fakeoid/models/
-- When any prerequisite is missing, lazy.nvim skips the plugin entirely (no install, no load).

local LLAMA_PORT = 8012
local MODEL_PATH = "~/.fakeoid/models/Qwen2.5-Coder-32B-Instruct-Q4_K_M.gguf"

local function llm_available()
  if vim.fn.executable("llama-server") ~= 1 then return false end
  if vim.fn.executable("rocminfo") ~= 1 then return false end
  local rocm_out = vim.fn.system("rocminfo 2>/dev/null | grep -c gfx1100")
  if tonumber(vim.trim(rocm_out)) == 0 then return false end
  if vim.fn.filereadable(vim.fn.expand(MODEL_PATH)) ~= 1 then return false end
  return true
end

local function is_port_in_use(port)
  local result = vim.fn.system("ss -tln sport = :" .. port .. " 2>/dev/null | grep -c LISTEN")
  return tonumber(vim.trim(result)) > 0
end

return {
  {
    "milanglacier/minuet-ai.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cond = llm_available,
    config = function()
      -- Start llama-server if not already running on the target port.
      -- If port is in use (e.g., fakeoid started its own llama-server), reuse it.
      local server_job = nil
      if not is_port_in_use(LLAMA_PORT) then
        local model = vim.fn.expand(MODEL_PATH)
        server_job = vim.fn.jobstart({
          "llama-server",
          "--model", model,
          "--port", tostring(LLAMA_PORT),
          "-ngl", "99",          -- offload all layers to GPU
          "--flash-attn", "on",  -- flash attention
          "-ub", "1024",
          "-b", "1024",
          "--ctx-size", "4096",  -- smaller context for completions (not full 32K)
          "--cache-reuse", "256",
        }, {
          on_exit = function(_, code)
            if code ~= 0 then
              vim.schedule(function()
                vim.notify("llama-server exited with code " .. code, vim.log.levels.WARN)
              end)
            end
            server_job = nil
          end,
        })
        if server_job <= 0 then
          vim.notify("Failed to start llama-server (jobstart returned " .. server_job .. ")", vim.log.levels.ERROR)
          server_job = nil
        end
      end

      -- Stop llama-server when neovim exits, but only if this instance started it
      vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
          if server_job then
            vim.fn.jobstop(server_job)
          end
        end,
      })

      require("minuet").setup({
        provider = "openai_fim_compatible",
        throttle = 1000,       -- ms between requests (GPU-bound, not cost-bound)
        debounce = 400,        -- ms after typing stops before requesting
        request_timeout = 3,   -- seconds
        n_completions = 1,     -- single completion (local model is slower than cloud)
        virtualtext = {
          auto_trigger_ft = {}, -- empty = all filetypes
          keymap = {
            accept = "<A-A>",       -- Alt-Shift-A: accept full suggestion
            accept_line = "<A-a>",  -- Alt-a: accept single line
            prev = "<A-[>",         -- Alt-[: previous suggestion
            next = "<A-]>",         -- Alt-]: next suggestion
            dismiss = "<A-e>",      -- Alt-e: dismiss suggestion
          },
        },
        provider_options = {
          openai_fim_compatible = {
            api_key = "NONE",  -- local server, no authentication needed
            end_point = "http://127.0.0.1:" .. LLAMA_PORT .. "/v1/completions",
            model = "qwen2.5-coder",
            name = "llama-server",
            optional = {
              max_tokens = 128,
              top_p = 0.9,
              temperature = 0.2,
            },
          },
        },
      })
    end,
  },
}
