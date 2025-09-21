-- Base specification for nvim-tree-docs
-- Provides core processors and functionality that other specs inherit from

local template_mod = require("nvim-tree-docs.template")

-- Create the base specification module
local mod_name = "base.base"
local module = {
  __build = template_mod.build_line,
  config = vim.tbl_deep_extend("force", {
    processors = {},
    slots = {},
  }, {}),
  ["doc-lang"] = nil,
  inherits = nil,
  lang = "base",
  module = mod_name,
  processors = {},
  spec = "base",
  templates = {},
  utils = {},
}

-- Extend with base (self-reference for consistency)
template_mod.extend_spec(module, "base.base")

-- Register this module in the loaded specs
template_mod.loaded_specs[mod_name] = module

-- %rest% processor - expands to include enabled slots not already in the list
module.processors["%rest%"] = {
  implicit = true,
  expand = function(slot_indexes, slot_config)
    local expanded = {}
    for ps_name, enabled in pairs(slot_config) do
      if enabled and not slot_indexes[ps_name] then
        table.insert(expanded, ps_name)
      end
    end
    return expanded
  end,
}

-- %content% processor - simply returns the content with no indentation
module.processors["%content%"] = {
  implicit = true,
  build = function(context)
    return context.content
  end,
  indent = function()
    return 0
  end,
}
