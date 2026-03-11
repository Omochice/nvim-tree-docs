describe("typst tinymist", function()
  ---@type integer
  local bufnr
  before_each(function()
    bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(bufnr)
    vim.bo[bufnr].filetype = "typst"
  end)
  it("should generate doc comment for function", function()
    local contents = {
      "#let greet(name) = {",
      '  "Hello, " + name',
      "}",
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    vim.treesitter.get_parser(bufnr, "typst"):parse()
    vim.api.nvim_win_set_cursor(0, { 1, 5 })

    require("nvim-tree-docs").doc_node_at_cursor()

    MiniTest.expect.equality(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), {
      "/// greet description",
      "/// - name: name description",
      "#let greet(name) = {",
      '  "Hello, " + name',
      "}",
    })
  end)
  it("should generate doc comment for function with multiple params", function()
    local contents = {
      "#let add(a, b) = a + b",
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    vim.treesitter.get_parser(bufnr, "typst"):parse()
    vim.api.nvim_win_set_cursor(0, { 1, 5 })

    require("nvim-tree-docs").doc_node_at_cursor()

    MiniTest.expect.equality(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), {
      "/// add description",
      "/// - a: a description",
      "/// - b: b description",
      "#let add(a, b) = a + b",
    })
  end)
  it("should generate doc comment for variable binding", function()
    local contents = {
      "#let x = 42",
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    vim.treesitter.get_parser(bufnr, "typst"):parse()
    vim.api.nvim_win_set_cursor(0, { 1, 5 })

    require("nvim-tree-docs").doc_node_at_cursor()

    MiniTest.expect.equality(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), {
      "/// x description",
      "#let x = 42",
    })
  end)
end)
