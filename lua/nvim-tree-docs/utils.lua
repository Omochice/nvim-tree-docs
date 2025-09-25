-- Utility functions for nvim-tree-docs
-- Provides helper functions for working with tree-sitter nodes, buffer content, and data structures

local M = {}

--- Generic position getter that searches through multiple keys
--- @param keys table: List of keys to search in priority order
--- @param default_position string: Default position type ("start" or "end")
--- @param entry table: Entry to search in
--- @return number, number, number: row, col, byte position
local function get_position(keys, default_position, entry)
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
  return get_position({ "start_point", "definition" }, "start", entry)
end

--- Get end position from entry (checks end_point, then definition)
--- @param entry table: Entry to get position from
--- @return number, number, number: row, col, byte position
function M.get_end_position(entry)
  return get_position({ "end_point", "definition" }, "end", entry)
end

--- Get edit start position (checks edit_start_point, start_point, then definition)
--- @param entry table: Entry to get position from
--- @return number, number, number: row, col, byte position
function M.get_edit_start_position(entry)
  return get_position({ "edit_start_point", "start_point", "definition" }, "start", entry)
end

--- Get edit end position (checks edit_end_point, end_point, then definition)
--- @param entry table: Entry to get position from
--- @return number, number, number: row, col, byte position
function M.get_edit_end_position(entry)
  return get_position({ "edit_end_point", "end_point", "definition" }, "end", entry)
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

--- Check if value is a table with a method
--- @param v any: Value to check
--- @param key string: Method name to check for
--- @return boolean: True if v is table and v[key] is function
function M.method(v, key)
  return type(v) == "table" and vim.is_callable(v[key])
end

return M
