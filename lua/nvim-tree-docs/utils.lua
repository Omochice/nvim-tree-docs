-- Utility functions for nvim-tree-docs
-- Provides helper functions for working with tree-sitter nodes, buffer content, and data structures

local M = {}

-- Namespace for highlighting
local ns = vim.api.nvim_create_namespace("nvim-tree-docs")

--- Get the start node from an entry
--- @param entry table: Entry containing start_point or definition
--- @return table?: Tree-sitter node if found
function M.get_start_node(entry)
  return (entry.start_point and entry.start_point.node) or (entry.definition and entry.definition.node)
end

--- Get the end node from an entry
--- @param entry table: Entry containing end_point or definition
--- @return table?: Tree-sitter node if found
function M.get_end_node(entry)
  return (entry.end_point and entry.end_point.node) or (entry.definition and entry.definition.node)
end

--- Generic position getter that searches through multiple keys
--- @param keys table: List of keys to search in priority order
--- @param default_position string: Default position type ("start" or "end")
--- @param entry table: Entry to search in
--- @return number, number, number: row, col, byte position
function M.get_position(keys, default_position, entry)
  local i = 1
  local result = nil

  while not result and (i <= #keys) do
    local key = keys[i]
    local match = entry[key]
    local has_match = type(match) == "table" and match.node
    local position = has_match and (match.position or default_position) or nil

    if has_match then
      if position == "start" then
        result = { match.node:start() }
      else
        result = { match.node:end_() }
      end
    end
    i = i + 1
  end

  return unpack(result or {})
end

--- Get start position from entry (checks start_point, then definition)
--- @param entry table: Entry to get position from
--- @return number, number, number: row, col, byte position
function M.get_start_position(entry)
  return M.get_position({ "start_point", "definition" }, "start", entry)
end

--- Get end position from entry (checks end_point, then definition)
--- @param entry table: Entry to get position from
--- @return number, number, number: row, col, byte position
function M.get_end_position(entry)
  return M.get_position({ "end_point", "definition" }, "end", entry)
end

--- Get edit start position (checks edit_start_point, start_point, then definition)
--- @param entry table: Entry to get position from
--- @return number, number, number: row, col, byte position
function M.get_edit_start_position(entry)
  return M.get_position({ "edit_start_point", "start_point", "definition" }, "start", entry)
end

--- Get edit end position (checks edit_end_point, end_point, then definition)
--- @param entry table: Entry to get position from
--- @return number, number, number: row, col, byte position
function M.get_edit_end_position(entry)
  return M.get_position({ "edit_end_point", "end_point", "definition" }, "end", entry)
end

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

--- Get all keys from table where value is truthy
--- @param tbl table: Table to scan
--- @return table: Array of truthy keys
function M.get_all_truthy_keys(tbl)
  local result = {}
  for k, v in pairs(tbl) do
    if v then
      table.insert(result, k)
    end
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

--- Highlight marks in buffer for debugging
--- @param marks table: Array of mark objects with line, start, stop
--- @param bufnr number: Buffer number
function M.highlight_marks(marks, bufnr)
  for _, mark in ipairs(marks) do
    local line = mark.line - 1
    vim.highlight.range(bufnr, ns, "Visual", { line, mark.start }, { line, mark.stop })
  end
end

return M
