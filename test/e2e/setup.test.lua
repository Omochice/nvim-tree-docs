describe("setup", function()
  it("should call setup without error", function()
    MiniTest.expect.no_error(function()
      require("nvim-tree-docs").setup()
    end)
  end)

  it("should attach to supported filetype buffer via FileType autocmd", function()
    require("nvim-tree-docs").setup()
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(bufnr)
    vim.bo[bufnr].filetype = "lua"

    vim.api.nvim_exec_autocmds("FileType", { buffer = bufnr })

    local keymaps = vim.api.nvim_buf_get_keymap(bufnr, "n")
    local has_doc_keymap = vim.iter(keymaps):any(function(m)
      return m.lhs == "gdd"
    end)
    MiniTest.expect.equality(has_doc_keymap, true)
  end)
end)
