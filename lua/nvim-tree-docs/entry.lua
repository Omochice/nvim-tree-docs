local M = {}

--- @class Entry
--- @field kind string Kind of the entry (e.g., "function", "variable")
--- @field definition table Definition match data
--- @field start_position fun(self: Entry): (number, number, number) Get start
--- @field end_position fun(self: Entry): (number, number, number) Get end position (row, col, byte)
--- @field edit_start_position fun(self: Entry): (number, number, number) Get edit start position (row, col, byte)
--- @field edit_end_position fun(self: Entry): (number, number, number) Get edit end position (row, col, byte)

local function get_position(keys, default_position, entry)
  local i = 1
  local result = nil

  while not result and (i <= #keys) do
    local key = keys[i]
    --- @type { node: TSNode, position?: string }
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

--- @return Entry
M.new = function(kind, definition)
  return {
    kind = kind,
    definition = definition,
    end_position = function(self)
      return get_position({ "end_point", "definition" }, "end", self)
    end,
    start_position = function(self)
      return get_position({ "start_point", "definition" }, "start", self)
    end,
    edit_start_position = function(self)
      return get_position({ "edit_start_point", "start_point", "definition" }, "start", self)
    end,
    edit_end_position = function(self)
      return get_position({ "edit_end_point", "end_point", "definition" }, "end", self)
    end,
  }
end

return M
