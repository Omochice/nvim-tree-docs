local M = {}

local group = vim.api.nvim_create_augroup("nvim-tree-docs", { clear = true })

local function is_supported(lang)
  return require("nvim-treesitter.query").get_query(lang, "docs") ~= nil
end

--- @param opts? Option
function M.setup(opts)
  require("nvim-tree-docs.configure").set(opts or {})
  vim.api.nvim_create_autocmd({ "FileType" }, {
    callback = function(args)
      require("nvim-tree-docs.internal").detach(args.buf)
      local lang = vim.treesitter.language.get_lang(args.match)
      if not is_supported(lang) then
        return
      end
      require("nvim-tree-docs.internal").attach(args.buf)
    end,
    group = group,
  })

  vim.api.nvim_create_autocmd({ "BufUnload" }, {
    callback = function(args)
      require("nvim-tree-docs.internal").detach(args.buf)
    end,
    group = group,
  })
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
