describe("lua luadoc", function()
  it("should generate lua docstring", function()
    local bufnr = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_set_current_buf(bufnr)
    vim.bo.filetype = "lua"
    local contents = {
      "local function sample(a, b)",
      "  return a + b",
      "end"
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    vim.treesitter.get_parser(bufnr, "lua"):parse()
    vim.api.nvim_win_set_cursor(0, { 1, 17 })

    require("nvim-tree-docs.internal").doc_node_at_cursor()

    assert.same(
      {
        "--- Description",
        "-- @param a The a",
        "-- @param b The b",
        "local function sample(a, b)",
        "  return a + b",
        "end"
      }
      , vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
  end)

  it("should generate luadoc for variable", function()
    local bufnr = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_set_current_buf(bufnr)
    vim.bo.filetype = "lua"
    local contents = {
      "local sample = 42",
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    vim.treesitter.get_parser(bufnr, "lua"):parse()
    vim.api.nvim_win_set_cursor(0, { 1, 7 })

    require("nvim-tree-docs.internal").doc_node_at_cursor()

    assert.same(
      {
        "--- Description",
        "local sample = 42",
      }
      , vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
  end)
end)
