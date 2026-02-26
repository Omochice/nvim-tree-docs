local template_mod = require("nvim-tree-docs.template")

local mod_name = "kotlin.kdoc"
local module = {
  __build = template_mod.build_line,
  config = vim.tbl_deep_extend("force", {
    processors = {},
    slots = {},
  }, {
    empty_line_after_description = true,
    slots = {
      ["function"] = {
        param = true,
        returns = true,
      },
      class = {},
    },
  }),
  ["doc-lang"] = nil,
  inherits = nil,
  lang = "kotlin",
  module = mod_name,
  processors = {},
  spec = "kdoc",
  templates = {},
  utils = {},
}

template_mod.extend_spec(module, "base.base")
template_mod.loaded_specs[mod_name] = module

module.templates["function"] = {
  "doc-start",
  "description",
  "param",
  "returns",
  "doc-end",
  "%content%",
}

module.templates.class = {
  "doc-start",
  "description",
  "doc-end",
  "%content%",
}

module.processors["doc-start"] = {
  implicit = true,
  build = function()
    return "/**"
  end,
}

module.processors["doc-end"] = {
  implicit = true,
  build = function()
    return " */"
  end,
}

module.processors.description = {
  implicit = true,
  build = function(context, info)
    local name = context.name and context["get-text"](context.name) or "item"
    local description = module.__build(" * ", { content = "The " .. name .. " description", mark = "tabstop" })
    local next_ps = info.processors[info.index + 1]

    if next_ps == "doc-end" or not context.conf({ "empty_line_after_description" }) then
      return description
    else
      return { description, " *" }
    end
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
      table.insert(
        result,
        module.__build(" * @param ", name, " ", { content = "The " .. name .. " param", mark = "tabstop" })
      )
    end
    return result
  end,
}

module.processors.returns = {
  when = function(context)
    return context.return_statement
  end,
  build = function()
    return module.__build(" * @return ", { content = "The result", mark = "tabstop" })
  end,
}
