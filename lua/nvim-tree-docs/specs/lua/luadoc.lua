-- LuaDoc specification for Lua
-- Generates LuaDoc-style documentation comments for Lua code

local template_mod = require("nvim-tree-docs.template")

-- Create the Lua LuaDoc specification module
local mod_name = "lua.luadoc"
local module = {
  __build = template_mod.build_line,
  config = vim.tbl_deep_extend("force", {
    processors = {},
    slots = {},
  }, {
    slots = {
      ["function"] = {
        param = true,
        returns = true,
      },
      variable = {},
    },
  }),
  ["doc-lang"] = nil,
  inherits = nil,
  lang = "lua",
  module = mod_name,
  processors = {},
  spec = "luadoc",
  templates = {},
  utils = {},
}

-- Extend with base
template_mod.extend_spec(module, "base.base")

-- Register this module
template_mod.loaded_specs[mod_name] = module

-- Define templates
module.templates["function"] = {
  "description",
  "param",
  "returns",
  "%content%",
}
module.templates.variable = { "description", "%content%" }

-- Define processors
module.processors.description = {
  implicit = true,
  build = function()
    return "--- Description"
  end,
}

module.processors.param = {
  when = function(context)
    return context.parameters and not context["empty?"](context.parameters)
  end,
  build = function(context)
    local result = {}
    for param in context.iter(context.parameters) do
      local name = context["get-text"](param.entry.name)
      table.insert(result, "--- @param " .. name .. " The " .. name)
    end
    return result
  end,
}
