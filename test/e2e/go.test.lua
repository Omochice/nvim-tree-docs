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
  it("should generate godoc for variable", function()
    local contents = {
      "var DefaultTimeout = 30",
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    vim.treesitter.get_parser(bufnr, "go"):parse()
    vim.api.nvim_win_set_cursor(0, { 1, 4 })

    require("nvim-tree-docs").doc_node_at_cursor()

    assert.same({
      "// DefaultTimeout description",
      "var DefaultTimeout = 30",
    }, vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
  end)
  it("should generate godoc for grouped variable declaration", function()
    local contents = {
      "var (",
      "\tDefaultTimeout = 30",
      ")",
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    vim.treesitter.get_parser(bufnr, "go"):parse()
    vim.api.nvim_win_set_cursor(0, { 2, 1 })

    require("nvim-tree-docs").doc_node_at_cursor()

    assert.same({
      "var (",
      "\t// DefaultTimeout description",
      "\tDefaultTimeout = 30",
      ")",
    }, vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
  end)
  it("should generate godoc for constant", function()
    local contents = {
      "const MaxRetries = 3",
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    vim.treesitter.get_parser(bufnr, "go"):parse()
    vim.api.nvim_win_set_cursor(0, { 1, 6 })

    require("nvim-tree-docs").doc_node_at_cursor()

    assert.same({
      "// MaxRetries description",
      "const MaxRetries = 3",
    }, vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
  end)
  it("should generate godoc for grouped constant declaration", function()
    local contents = {
      "const (",
      "\tMaxRetries = 3",
      ")",
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    vim.treesitter.get_parser(bufnr, "go"):parse()
    vim.api.nvim_win_set_cursor(0, { 2, 1 })

    require("nvim-tree-docs").doc_node_at_cursor()

    assert.same({
      "const (",
      "\t// MaxRetries description",
      "\tMaxRetries = 3",
      ")",
    }, vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
  end)
end)
