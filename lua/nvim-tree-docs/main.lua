-- Main module for nvim-tree-docs
-- Handles initialization and treesitter module registration

local M = {}

--- Initialize the nvim-tree-docs plugin
--- Registers the tree_docs module with nvim-treesitter
function M.init()
  local ts = require("nvim-treesitter")
  local queries = require("nvim-treesitter.query")

  return ts.define_modules({
    tree_docs = {
      module_path = "nvim-tree-docs.internal",
      keymaps = {
        doc_node_at_cursor = "gdd",
        doc_all_in_range = "gdd",
        edit_doc_at_cursor = "gde",
      },
      is_supported = function(lang)
        return queries.get_query(lang, "docs") ~= nil
      end,
    },
  })
end

return M
