local M = {}

--- @param opts Option
function M.configure(opts)
  require("nvim-tree-docs.configure").set(opts)
end

function M.doc_node_at_cursor()
  return require("nvim-tree-docs.internal").doc_node_at_cursor()
end

function M.doc_all_in_range()
  return require("nvim-tree-docs.internal").doc_all_in_range()
end

function M.edit_doc_at_cursor()
  return require("nvim-tree-docs.internal").edit_doc_at_cursor()
end

return M
