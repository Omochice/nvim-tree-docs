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

    MiniTest.expect.equality(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), {
      "/**",
      " * The main description",
      " */",
      "fun main() {",
      "}",
    })
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

    MiniTest.expect.equality(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), {
      "/**",
      " * The sample description",
      " *",
      " * @param a The a param",
      " * @param b The b param",
      " */",
      "fun sample(a: Int, b: String) {",
      "}",
    })
  end)
  it("should generate kdoc with @return for function with return", function()
    local contents = {
      "fun greet(name: String): String {",
      '    return "Hello, $name"',
      "}",
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    vim.treesitter.get_parser(bufnr, "kotlin"):parse()
    vim.api.nvim_win_set_cursor(0, { 1, 4 })

    require("nvim-tree-docs").doc_node_at_cursor()

    MiniTest.expect.equality(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), {
      "/**",
      " * The greet description",
      " *",
      " * @param name The name param",
      " * @return The result",
      " */",
      "fun greet(name: String): String {",
      '    return "Hello, $name"',
      "}",
    })
  end)
  it("should generate kdoc for class", function()
    local contents = {
      "class MyClass {",
      "}",
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    vim.treesitter.get_parser(bufnr, "kotlin"):parse()
    vim.api.nvim_win_set_cursor(0, { 1, 6 })

    require("nvim-tree-docs").doc_node_at_cursor()

    MiniTest.expect.equality(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), {
      "/**",
      " * The MyClass description",
      " */",
      "class MyClass {",
      "}",
    })
  end)
  it("should generate kdoc for interface", function()
    local contents = {
      "interface Repository {",
      "    fun findById(id: Long): Any",
      "}",
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    vim.treesitter.get_parser(bufnr, "kotlin"):parse()
    vim.api.nvim_win_set_cursor(0, { 1, 10 })

    require("nvim-tree-docs").doc_node_at_cursor()

    MiniTest.expect.equality(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), {
      "/**",
      " * The Repository description",
      " */",
      "interface Repository {",
      "    fun findById(id: Long): Any",
      "}",
    })
  end)
  it("should generate kdoc for property", function()
    local contents = {
      'val name = "hello"',
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    vim.treesitter.get_parser(bufnr, "kotlin"):parse()
    vim.api.nvim_win_set_cursor(0, { 1, 4 })

    require("nvim-tree-docs").doc_node_at_cursor()

    MiniTest.expect.equality(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), {
      "/**",
      " * The name description",
      " */",
      'val name = "hello"',
    })
  end)
  it("should generate kdoc with @return for expression-bodied function", function()
    local contents = {
      "fun add(a: Int, b: Int): Int = a + b",
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    vim.treesitter.get_parser(bufnr, "kotlin"):parse()
    vim.api.nvim_win_set_cursor(0, { 1, 4 })

    require("nvim-tree-docs").doc_node_at_cursor()

    MiniTest.expect.equality(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), {
      "/**",
      " * The add description",
      " *",
      " * @param a The a param",
      " * @param b The b param",
      " * @return The result",
      " */",
      "fun add(a: Int, b: Int): Int = a + b",
    })
  end)
  it("should generate kdoc with @return for function with nullable return type", function()
    local contents = {
      "fun find(id: Int): String? {",
      "    return null",
      "}",
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    vim.treesitter.get_parser(bufnr, "kotlin"):parse()
    vim.api.nvim_win_set_cursor(0, { 1, 4 })

    require("nvim-tree-docs").doc_node_at_cursor()

    MiniTest.expect.equality(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), {
      "/**",
      " * The find description",
      " *",
      " * @param id The id param",
      " * @return The result",
      " */",
      "fun find(id: Int): String? {",
      "    return null",
      "}",
    })
  end)
  it("should generate kdoc with @return for function returning function type", function()
    local contents = {
      "fun create(): (Int) -> String {",
      "    return { it.toString() }",
      "}",
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    vim.treesitter.get_parser(bufnr, "kotlin"):parse()
    vim.api.nvim_win_set_cursor(0, { 1, 4 })

    require("nvim-tree-docs").doc_node_at_cursor()

    MiniTest.expect.equality(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), {
      "/**",
      " * The create description",
      " *",
      " * @return The result",
      " */",
      "fun create(): (Int) -> String {",
      "    return { it.toString() }",
      "}",
    })
  end)
  it("should generate kdoc for object", function()
    local contents = {
      "object Singleton {",
      "}",
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
    vim.treesitter.get_parser(bufnr, "kotlin"):parse()
    vim.api.nvim_win_set_cursor(0, { 1, 7 })

    require("nvim-tree-docs").doc_node_at_cursor()

    MiniTest.expect.equality(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), {
      "/**",
      " * The Singleton description",
      " */",
      "object Singleton {",
      "}",
    })
  end)
end)
