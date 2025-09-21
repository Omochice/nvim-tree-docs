-- TSDoc specification for TypeScript
-- Extends JSDoc with TypeScript-specific configuration

local template_mod = require("nvim-tree-docs.template")

-- Create the TypeScript TSDoc specification module
local mod_name = "typescript.tsdoc"
local module = {
  __build = template_mod.build_line,
  config = vim.tbl_deep_extend("force", {
    processors = {},
    slots = {},
  }, {
    include_types = false,
    empty_line_after_description = true,
    slots = {
      ["function"] = {
        export = false,
        generator = false,
        ["function"] = false,
        yields = false,
      },
      variable = {
        type = false,
        export = false,
      },
      class = {
        class = false,
        export = false,
        extends = false,
      },
      member = {
        memberof = false,
        type = false,
      },
      method = {
        memberof = false,
      },
    },
  }),
  ["doc-lang"] = nil,
  inherits = nil,
  lang = "typescript",
  module = mod_name,
  processors = {},
  spec = "tsdoc",
  templates = {},
  utils = {},
}

-- Extend with base and JavaScript JSDoc
template_mod.extend_spec(module, "base.base")
template_mod.extend_spec(module, "javascript.jsdoc")

-- Register this module
template_mod.loaded_specs[mod_name] = module
