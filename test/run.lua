vim.opt.runtimepath:append(vim.fn.getcwd())

local function save_luacov_stats()
  local ok, runner = pcall(require, "luacov.runner")
  if ok then
    runner.save_stats()
  end
end

-- Neovim's `-l` flag calls C-level os_exit() without closing Lua state,
-- so LuaCov's atexit handler never fires. Try multiple hooks to flush stats.
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = save_luacov_stats,
})

require("mini.test").setup({
  collect = {
    emulate_busted = true,
    find_files = function()
      return vim.fn.globpath("test/e2e", "*.test.lua", true, true)
    end,
  },
  execute = {
    reporter = require("mini.test").gen_reporter.stdout({ group_depth = 2 }),
  },
})

MiniTest.run()
save_luacov_stats()
