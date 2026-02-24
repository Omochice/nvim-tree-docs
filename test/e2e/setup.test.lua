describe("setup", function()
  it("should call setup without error", function()
    assert.has_no.errors(function()
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
    assert.is_true(has_doc_keymap)
  end)
end)
