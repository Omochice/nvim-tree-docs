-- Editing module for nvim-tree-docs
-- Handles in-place editing of documentation comments with syntax highlighting

local M = {}

-- Module dependencies
local tsq = vim.treesitter.query

--- Namespace for highlighting editable regions
local ns = vim.api.nvim_create_namespace("doc-edit")

--- Extract editable regions from documentation comment
--- @param args table: Arguments containing lang, doc-lang, node, bufnr
--- @return table: Parsed data with editable regions
function M.get_doc_comment_data(args)
  local lang = args.lang
  local doc_lang = args["doc-lang"]
  local node = args.node
  local bufnr = args.bufnr

  -- Get the text content of the documentation node
  local doc_string = vim.treesitter.get_node_text(node, bufnr)

  -- Parse the documentation string with the documentation language parser
  local parser = vim.treesitter.get_string_parser(doc_string, doc_lang)
  local query = tsq.get_query(doc_lang, "edits")
  local iter = query:iter_matches(parser:parse():root(), doc_string, 1, #doc_string + 1)

  local result = {}
  local item = { iter() }

  -- Iterate through all matches and group by capture name
  while item[1] do
    local pattern_id = item[1]
    local matches = item[2]

    for id, match_node in pairs(matches) do
      local match_name = query.captures[id]
      if not result[match_name] then
        result[match_name] = {}
      end
      table.insert(result[match_name], match_node)
    end

    item = { iter() }
  end

  return result
end

--- Edit documentation at cursor with visual highlighting of editable regions
--- @param args table: Arguments containing lang, spec-name, bufnr, doc-lang, node
function M.edit_doc(args)
  local bufnr = args.bufnr
  local doc_node = args.node
  local comment_data = M.get_doc_comment_data(args)
  local edit_nodes = comment_data.edit or {}
  local sr = doc_node:range()

  -- Clear any existing highlights
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  -- Highlight each editable region
  for _, node in ipairs(edit_nodes) do
    local dsr, dsc, der, dec = node:range()
    vim.highlight.range(bufnr, ns, "Visual", { dsr + sr, dsc }, { der + sr, dec })
  end
end

return M
