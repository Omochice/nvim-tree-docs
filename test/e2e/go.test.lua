describe("go godoc", function()
  ---@type integer
  local bufnr
  before_each(function()
    bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(bufnr)
    vim.bo[bufnr].filetype = "go"
  end)
  it("should generate godoc for function", function()
    local contents = {
      "func main() {",
      "}",
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    vim.treesitter.get_parser(bufnr, "go"):parse()
    vim.api.nvim_win_set_cursor(0, { 1, 5 })

    require("nvim-tree-docs").doc_node_at_cursor()

    assert.same({
      "// main description",
      "func main() {",
      "}",
    }, vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
  end)
  it("should generate godoc for function with parameters", function()
    local contents = {
      "func Sample(a int, b string) error {",
      "\treturn nil",
      "}",
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    vim.treesitter.get_parser(bufnr, "go"):parse()
    vim.api.nvim_win_set_cursor(0, { 1, 5 })

    require("nvim-tree-docs").doc_node_at_cursor()

    assert.same({
      "// Sample description",
      "func Sample(a int, b string) error {",
      "\treturn nil",
      "}",
    }, vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
  end)
  it("should generate godoc for method", function()
    local contents = {
      "func (s *Server) Start() error {",
      "\treturn nil",
      "}",
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    vim.treesitter.get_parser(bufnr, "go"):parse()
    vim.api.nvim_win_set_cursor(0, { 1, 18 })

    require("nvim-tree-docs").doc_node_at_cursor()

    assert.same({
      "// Start description",
      "func (s *Server) Start() error {",
      "\treturn nil",
      "}",
    }, vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
  end)
  it("should generate godoc for struct type", function()
    local contents = {
      "type Server struct {",
      "\tHost string",
      "\tPort int",
      "}",
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    vim.treesitter.get_parser(bufnr, "go"):parse()
    vim.api.nvim_win_set_cursor(0, { 1, 5 })

    require("nvim-tree-docs").doc_node_at_cursor()

    assert.same({
      "// Server description",
      "type Server struct {",
      "\tHost string",
      "\tPort int",
      "}",
    }, vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
  end)
  it("should generate godoc for interface type", function()
    local contents = {
      "type Reader interface {",
      "\tRead(p []byte) (n int, err error)",
      "}",
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    vim.treesitter.get_parser(bufnr, "go"):parse()
    vim.api.nvim_win_set_cursor(0, { 1, 5 })

    require("nvim-tree-docs").doc_node_at_cursor()

    assert.same({
      "// Reader description",
      "type Reader interface {",
      "\tRead(p []byte) (n int, err error)",
      "}",
    }, vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
  end)
end)
