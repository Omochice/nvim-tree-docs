-- Utility functions for nvim-tree-docs
-- Provides helper functions for working with tree-sitter nodes, buffer content, and data structures

local M = {}

--- Get buffer number, defaulting to current buffer
--- @param bufnr number?: Buffer number
--- @return number: Buffer number
function M.get_bufnr(bufnr)
  return bufnr or vim.api.nvim_get_current_buf()
end

--- Get buffer content between positions
--- @param start_row number: Starting row
--- @param start_col number: Starting column (unused but kept for API compatibility)
--- @param end_row number: Ending row
--- @param end_col number: Ending column (unused but kept for API compatibility)
--- @param bufnr number: Buffer number
--- @return table: Lines from buffer
function M.get_buf_content(start_row, start_col, end_row, end_col, bufnr)
  return vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
end

--- Get nested value from table using path
--- @param path table|string: Path as array of keys or dot-separated string
--- @param tbl table: Table to search in
--- @param default any?: Default value if path not found
--- @return any: Found value or default
function M.get(path, tbl, default)
  local segments
  if type(path) == "string" then
    segments = vim.split(path, "%.")
  else
    segments = path
  end

  local result = tbl
  for _, segment in ipairs(segments) do
    if type(result) == "table" then
      result = result[segment]
    else
      result = nil
      break
    end
  end

  return result == nil and default or result
end

--- Create inverse mapping of array (value -> index)
--- @param tbl table: Array to invert
--- @return table: Inverted mapping
function M.make_inverse_list(tbl)
  local result = {}
  for i, v in ipairs(tbl) do
    result[v] = i
  end
  return result
end

--- Check if value is a table with a method
--- @param v any: Value to check
--- @param key string: Method name to check for
--- @return boolean: True if v is table and v[key] is function
function M.method(v, key)
  return type(v) == "table" and vim.is_callable(v[key])
end

return M
