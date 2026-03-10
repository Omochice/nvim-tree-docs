vim.opt.runtimepath:append(vim.fn.getcwd())

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
