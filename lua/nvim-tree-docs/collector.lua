-- Collector module for nvim-tree-docs
-- Manages collections of tree-sitter match data with ordered iteration

local M = {}

--- Helper function to get table keys (replacement for core.keys)
local function get_keys(tbl)
  local keys = {}
  for k, _ in pairs(tbl) do
    table.insert(keys, k)
  end
  return keys
end

-- Collector metatable to enable array-like access by index
local collector_metatable = {
  __index = function(tbl, key)
    if type(key) == "number" then
      local id = tbl.__order[key]
      if id then
        return tbl.__entries[id]
      else
        return nil
      end
    else
      return rawget(tbl, key)
    end
  end,
}

--- Create a new collector instance
--- @return table: New collector with entries and order tracking
function M.new_collector()
  return setmetatable({
    __entries = {}, -- Maps node IDs to entry data
    __order = {}, -- Array of node IDs in insertion order
  }, collector_metatable)
end

--- Check if a value is a collector
--- @param value any: Value to check
--- @return boolean: True if value is a collector
function M.is_collector(value)
  return type(value) == "table" and type(value.__entries) == "table"
end

--- Check if a collector is empty
--- @param collector table: Collector to check
--- @return boolean: True if collector has no entries
function M.is_collector_empty(collector)
  return #collector.__order == 0
end

--- Create an iterator for a collector
--- @param collector table: Collector to iterate over
--- @return function: Iterator function
function M.iterate_collector(collector)
  local i = 1
  return function()
    local id = collector.__order[i]
    if id then
      i = i + 1
      return {
        index = i - 1,
        entry = collector.__entries[id],
      }
    else
      return nil
    end
  end
end

--- Generate a unique ID for a tree-sitter node based on its range
--- @param node table: Tree-sitter node
--- @return string: Unique identifier
function M.get_node_id(node)
  local srow, scol, erow, ecol = node:range()
  return string.format("%d_%d_%d_%d", srow, scol, erow, ecol)
end

--- Internal collection helper that recursively processes matches
--- @param collector table: Target collector
--- @param entry table: Entry to modify
--- @param match table: Match data to process
--- @param key string: Key being processed
--- @param add_fn function: Function to call for recursive processing
local function collect_(collector, entry, match, key, add_fn)
  if match.definition then
    -- If this match has a definition, create a sub-collector if needed
    if not entry[key] then
      entry[key] = M.new_collector()
    end
    return add_fn(entry[key], key, match, collect_)
  elseif not entry[key] then
    -- Simple assignment if key doesn't exist
    entry[key] = match
  elseif key == "start_point" and match.node then
    -- For start points, keep the earliest one
    local _, _, current_start = entry[key].node:start()
    local _, _, new_start = match.node:start()
    if new_start < current_start then
      entry[key] = match
    end
  elseif key == "end_point" and match.node then
    -- For end points, keep the latest one
    local _, _, current_end = entry[key].node:end_()
    local _, _, new_end = match.node:end_()
    if new_end > current_end then
      entry[key] = match
    end
  end
end

--- Add a match to the collector
--- @param collector table: Target collector
--- @param kind string: Kind of match (e.g., "function", "variable")
--- @param match table: Match data from tree-sitter query
function M.add_match(collector, kind, match)
  if not (match and match.definition) then
    return
  end

  local def = match.definition
  local def_node = def.node
  local node_id = M.get_node_id(def_node)

  -- Add entry if it doesn't exist, maintaining order by start position
  if not collector.__entries[node_id] then
    local order_index = 1
    local _, _, def_start_byte = def_node:start()
    local entry_keys = get_keys(collector.__entries)
    local done = false
    local i = 1

    -- Find the correct insertion position to maintain order
    while not done do
      local entry_key = entry_keys[i]
      local entry = entry_key and collector.__entries[entry_key]

      if not entry then
        done = true
      else
        local _, _, start_byte = entry.definition.node:start()
        if def_start_byte < start_byte then
          done = true
        else
          order_index = order_index + 1
          i = i + 1
        end
      end
    end

    table.insert(collector.__order, order_index, node_id)
    collector.__entries[node_id] = {
      kind = kind,
      definition = def,
    }
  end

  -- Process all sub-matches recursively
  for key, submatch in pairs(match) do
    if key ~= "definition" then
      collect_(collector, collector.__entries[node_id], submatch, key, M.add_match)
    end
  end
end

return M
