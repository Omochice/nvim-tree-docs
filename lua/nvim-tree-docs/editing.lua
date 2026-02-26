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
local function get_doc_comment_data(args)
  local lang = args.lang
  local doc_lang = args["doc-lang"]
  local node = args.node
  local bufnr = args.bufnr

  -- Get the text content of the documentation node
  local doc_string = vim.treesitter.get_node_text(node, bufnr)

  -- Parse the documentation string with the documentation language parser
  local parser = vim.treesitter.get_string_parser(doc_string, doc_lang)
  local query = tsq.get(doc_lang, "edits")
  if not query then
    return {}
  end
  local tree = parser:parse()[1]
  local result = {}

  for _, match in query:iter_matches(tree:root(), doc_string, 0, -1, { all = true }) do
    for id, nodes in pairs(match) do
      local match_name = query.captures[id]
      if not result[match_name] then
        result[match_name] = {}
      end
      for _, node in ipairs(nodes) do
        table.insert(result[match_name], node)
      end
    end
  end

  return result
end

--- Edit documentation at cursor with visual highlighting of editable regions
--- @param args table: Arguments containing lang, spec-name, bufnr, doc-lang, node
function M.edit_doc(args)
  local bufnr = args.bufnr
  local doc_node = args.node
  local comment_data = get_doc_comment_data(args)
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
