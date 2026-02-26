local template_mod = require("nvim-tree-docs.template")

local mod_name = "go.godoc"
local module = {
  __build = template_mod.build_line,
  config = vim.tbl_deep_extend("force", {
    processors = {},
    slots = {},
  }, {
    slots = {
      ["function"] = {},
    },
  }),
  ["doc-lang"] = nil,
  inherits = nil,
  lang = "go",
  module = mod_name,
  processors = {},
  spec = "godoc",
  templates = {},
  utils = {},
}

template_mod.extend_spec(module, "base.base")
template_mod.loaded_specs[mod_name] = module

module.templates["function"] = {
  "description",
  "%content%",
}

module.processors.description = {
  implicit = true,
  build = function(context)
    local name = context.name and context["get-text"](context.name) or "Description"
    return "// " .. name .. " description"
  end,
}
