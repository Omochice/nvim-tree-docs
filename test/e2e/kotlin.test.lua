describe("kotlin kdoc", function()
  ---@type integer
  local bufnr
  before_each(function()
    bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(bufnr)
    vim.bo[bufnr].filetype = "kotlin"
  end)
  it("should generate kdoc for function", function()
    local contents = {
      "fun main() {",
      "}",
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    vim.treesitter.get_parser(bufnr, "kotlin"):parse()
    vim.api.nvim_win_set_cursor(0, { 1, 4 })

    require("nvim-tree-docs").doc_node_at_cursor()

    assert.same({
      "/**",
      " * The main description",
      " */",
      "fun main() {",
      "}",
    }, vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
  end)
  it("should generate kdoc with @param for function with parameters", function()
    local contents = {
      "fun sample(a: Int, b: String) {",
      "}",
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    vim.treesitter.get_parser(bufnr, "kotlin"):parse()
    vim.api.nvim_win_set_cursor(0, { 1, 4 })

    require("nvim-tree-docs").doc_node_at_cursor()

    assert.same({
      "/**",
      " * The sample description",
      " *",
      " * @param a The a param",
      " * @param b The b param",
      " */",
      "fun sample(a: Int, b: String) {",
      "}",
    }, vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
  end)
end)
