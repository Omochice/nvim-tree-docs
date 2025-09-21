describe("typescript jsdoc", function()
  it("should generate typescript jsdoc", function()
    local bufnr = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_set_current_buf(bufnr)
    vim.bo.filetype = "typescript"
    local contents = {
      "function sample(a: string, b: number): string {",
      "  return a + b;",
      "}",
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    vim.treesitter.get_parser(bufnr, "typescript"):parse()
    vim.api.nvim_win_set_cursor(0, { 1, 9 })

    require("nvim-tree-docs").doc_node_at_cursor()

    assert.same({
      "/**",
      " * The sample description",
      " *",
      " * @param a - The a param",
      " * @param b - The b param",
      " * @returns The result",
      " */",
      "function sample(a: string, b: number): string {",
      "  return a + b;",
      "}",
    }, vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
  end)

  it("should generate jsdoc for variable", function()
    local bufnr = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_set_current_buf(bufnr)
    vim.bo.filetype = "typescript"
    local contents = {
      "const sample = 42;",
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    vim.treesitter.get_parser(bufnr, "typescript"):parse()
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
    local bufnr = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_set_current_buf(bufnr)
    vim.bo.filetype = "typescript"
    local contents = {
      "class A {",
      "  foo = 42;",
      "}",
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    vim.treesitter.get_parser(bufnr, "typescript"):parse()
    vim.api.nvim_win_set_cursor(0, { 1, 7 })

    require("nvim-tree-docs").doc_node_at_cursor()

    assert.same({
      "/**",
      " * The A description",
      " */",
      "class A {",
      "  foo = 42;",
      "}",
    }, vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
  end)

  it("should generate jsdoc for method", function()
    local bufnr = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_set_current_buf(bufnr)
    vim.bo.filetype = "typescript"
    local contents = {
      "class A {",
      "  foo = 42;",
      "}",
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    vim.treesitter.get_parser(bufnr, "typescript"):parse()
    vim.api.nvim_win_set_cursor(0, { 2, 3 })

    require("nvim-tree-docs").doc_node_at_cursor()

    assert.same({
      "class A {",
      "  /**",
      "   * The foo description",
      "   */",
      "  foo = 42;",
      "}",
    }, vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
  end)
end)
