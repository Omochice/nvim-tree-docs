local template_mod = require("nvim-tree-docs.template")

local mod_name = "typst.tinymist"
local module = {
  __build = template_mod.build_line,
  config = vim.tbl_deep_extend("force", {
    processors = {},
    slots = {},
  }, {
    slots = {
      ["function"] = {
        param = true,
      },
      variable = {},
    },
  }),
  ["doc-lang"] = nil,
  inherits = nil,
  lang = "typst",
  module = mod_name,
  processors = {},
  spec = "tinymist",
  templates = {},
  utils = {},
}

template_mod.extend_spec(module, "base.base")
template_mod.loaded_specs[mod_name] = module

module.templates["function"] = {
  "description",
  "param",
  "%content%",
}

module.templates.variable = {
  "description",
  "%content%",
}

module.processors.description = {
  implicit = true,
  build = function(context)
    local name = context.name and context["get-text"](context.name)
    local row = context["start-line"]
    local bufnr = context.bufnr or vim.api.nvim_get_current_buf()
    local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
    local indent_str = (line and line:match("^(%s*)")) or ""
    if name and name ~= "" then
      return indent_str .. "/// " .. name .. " description"
    end
    return indent_str .. "/// Description"
  end,
  indent = function()
    return 0
  end,
}

module.processors.param = {
  when = function(context)
    return context.parameters and not context["empty?"](context.parameters)
  end,
  build = function(context)
    local result = {}
    local row = context["start-line"]
    local bufnr = context.bufnr or vim.api.nvim_get_current_buf()
    local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
    local indent_str = (line and line:match("^(%s*)")) or ""
    for param in context.iter(context.parameters) do
      local name = context["get-text"](param.entry.name)
      table.insert(result, indent_str .. "/// - " .. name .. ": " .. name .. " description")
    end
    return result
  end,
  indent = function()
    return 0
  end,
}
