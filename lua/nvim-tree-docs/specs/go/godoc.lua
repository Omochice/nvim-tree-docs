-- GoDoc specification for Go
-- Generates GoDoc-style documentation comments for Go code
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
      method = {},
      type = {},
      variable = {},
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

module.templates.method = {
  "description",
  "%content%",
}

module.templates.type = {
  "description",
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
    if name and name ~= "" then
      return "// " .. name .. " description"
    end
    return "// Description"
  end,
}
