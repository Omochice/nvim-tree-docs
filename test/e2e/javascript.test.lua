describe("javascript jsdoc", function()
  ---@type integer
  local bufnr
  before_each(function()
    bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(bufnr)
    vim.bo[bufnr].filetype = "javascript"
  end)
  it("should generate jsdoc for function", function()
    local contents = {
      "function sample(a, b) {",
      "  return a + b;",
      "}",
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    vim.treesitter.get_parser(bufnr, "javascript"):parse()
    vim.api.nvim_win_set_cursor(0, { 1, 9 })

    require("nvim-tree-docs").doc_node_at_cursor()

    assert.same({
      "/**",
      " * The sample description",
      " * @function sample",
      " * @param {any} a - The a param",
      " * @param {any} b - The b param",
      " * @returns {any} The result",
      " */",
      "function sample(a, b) {",
      "  return a + b;",
      "}",
    }, vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
  end)

  it("should generate jsdoc for variable", function()
    local contents = {
      "const sample = 42;",
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    vim.treesitter.get_parser(bufnr, "javascript"):parse()
    vim.api.nvim_win_set_cursor(0, { 1, 13 })

    require("nvim-tree-docs").doc_node_at_cursor()

    assert.same({
      "/**",
      " * The sample description",
      " */",
      "const sample = 42;",
    }, vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
  end)

  it("should generate jsdoc for class", function()
    local contents = {
      "class A {",
      "  foo = 42;",
      "}",
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    vim.treesitter.get_parser(bufnr, "javascript"):parse()
    vim.api.nvim_win_set_cursor(0, { 1, 7 })

    require("nvim-tree-docs").doc_node_at_cursor()

    assert.same({
      "/**",
      " * The A description",
      " * @class A",
      " */",
      "class A {",
      "  foo = 42;",
      "}",
    }, vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
  end)

  it("should generate jsdoc for method", function()
    local contents = {
      "class A {",
      "  foo = 42;",
      "}",
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    vim.treesitter.get_parser(bufnr, "javascript"):parse()
    vim.api.nvim_win_set_cursor(0, { 2, 3 })

    require("nvim-tree-docs").doc_node_at_cursor()

    assert.same({
      "class A {",
      "  /**",
      "   * The foo description",
      "   * @memberof A",
      "   */",
      "  foo = 42;",
      "}",
    }, vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
  end)
end)
