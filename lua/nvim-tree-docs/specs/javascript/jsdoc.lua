-- JSDoc specification for JavaScript
-- Generates JSDoc-style documentation comments for JavaScript/TypeScript

local template_mod = require("nvim-tree-docs.template")

-- Create the JavaScript JSDoc specification module
local mod_name = "javascript.jsdoc"
local module = {
  __build = template_mod.build_line,
  config = vim.tbl_deep_extend("force", {
    processors = {},
    slots = {},
  }, {
    include_types = true,
    empty_line_after_description = false,
    slots = {
      ["function"] = {
        param = true,
        example = false,
        returns = true,
        ["function"] = true,
        generator = true,
        template = true,
        yields = true,
        export = true,
      },
      variable = {
        type = true,
        export = true,
      },
      class = {
        class = true,
        example = false,
        export = true,
        extends = true,
      },
      member = {
        memberof = true,
        type = true,
      },
      method = {
        memberof = true,
        example = false,
        yields = true,
        generator = true,
        param = true,
        returns = true,
      },
      module = {
        module = true,
      },
    },
  }),
  ["doc-lang"] = "jsdoc",
  inherits = nil,
  lang = "javascript",
  module = mod_name,
  processors = {},
  spec = "jsdoc",
  templates = {},
  utils = {},
}

-- Extend with base
template_mod.extend_spec(module, "base.base")

-- Register this module
template_mod.loaded_specs[mod_name] = module

-- Define templates
module.templates["function"] = {
  "doc-start",
  "description",
  "function",
  "generator",
  "yields",
  "%rest%",
  "param",
  "returns",
  "example",
  "doc-end",
  "%content%",
}

module.templates.variable = {
  "doc-start",
  "description",
  "%rest%",
  "doc-end",
  "%content%",
}

module.templates.method = {
  "doc-start",
  "description",
  "memberof",
  "%rest%",
  "param",
  "returns",
  "example",
  "doc-end",
  "%content%",
}

module.templates.class = {
  "doc-start",
  "description",
  "class",
  "extends",
  "%rest%",
  "example",
  "doc-end",
  "%content%",
}

module.templates.member = {
  "doc-start",
  "description",
  "memberof",
  "%rest%",
  "doc-end",
  "%content%",
}

module.templates.module = {
  "doc-start",
  "description",
  "module",
  "%rest%",
  "doc-end",
}

-- Define processors
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

module.processors.returns = {
  when = function(context)
    return context.return_statement
  end,
  build = function(context)
    local type_str = module.utils["get-marked-type"](context, " ")
    return module.__build(" * @returns", type_str, {
      content = "The result",
      mark = "tabstop",
    })
  end,
}

module.processors["function"] = {
  when = function(context)
    return not context.generator
  end,
  build = function(context)
    local name = context["get-text"](context.name)
    return module.__build(" * @function ", name)
  end,
}

module.processors.module = {
  build = function(context)
    local filename = vim.fn.expand("%:t:r")
    return module.__build(" * @module ", {
      content = filename,
      mark = "tabstop",
    })
  end,
}

module.processors.template = {
  when = function(context)
    return context.generics
  end,
  build = function(context)
    return module.utils["build-generics"](context, "template")
  end,
}

module.processors.typeParam = {
  when = function(context)
    return context.generics
  end,
  build = function(context)
    return module.utils["build-generics"](context, "typeParam")
  end,
}

module.processors.extends = {
  when = function(context)
    return context.extends
  end,
  build = function(context)
    local extends_name = context["get-text"](context.extends)
    return module.__build(" * @extends ", extends_name)
  end,
}

module.processors.class = {
  build = function(context)
    local name = context["get-text"](context.name)
    return module.__build(" * @class ", name)
  end,
}

module.processors.generator = {
  when = function(context)
    return context.generator
  end,
}

module.processors.yields = {
  when = function(context)
    return context.yields
  end,
  build = function(context)
    local type_str = module.utils["get-marked-type"](context, "")
    return module.__build(" * @yields", type_str)
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

module.processors.type = {
  when = function(context)
    return context.type
  end,
  build = function(context)
    local type_str = module.utils["get-marked-type"](context, " ")
    return module.__build(" * @type", type_str)
  end,
}

module.processors.export = {
  when = function(context)
    return context.export
  end,
}

module.processors.param = {
  when = function(context)
    return context.parameters and not context["empty?"](context.parameters)
  end,
  build = function(context)
    local result = {}
    for param in context.iter(context.parameters) do
      local param_name = module.utils["get-param-name"](context, param.entry)
      local type_str = module.utils["get-marked-type"](context, " ")
      local name = context["get-text"](param.entry.name)

      table.insert(
        result,
        module.__build(
          " * @param",
          type_str,
          param_name,
          " - ",
          { content = "The " .. name .. " param", mark = "tabstop" }
        )
      )
    end
    return result
  end,
}

module.processors.memberof = {
  when = function(context)
    return context.class
  end,
  build = function(context)
    local class_name = context["get-text"](context.class)
    return module.__build(" * @memberof ", class_name)
  end,
}

-- Default processor
module.processors.__default = {
  build = function(context, info)
    return module.__build(" * @", info.name)
  end,
}

-- Utility functions
module.utils["get-param-name"] = function(context, param)
  if param.default_value then
    return string.format("%s=%s", context["get-text"](param.name), context["get-text"](param.default_value))
  else
    return context["get-text"](param.name)
  end
end

module.utils["get-marked-type"] = function(context, not_found)
  if context.conf({ "include_types" }) then
    return " {any} "
  else
    return not_found or ""
  end
end

module.utils["build-generics"] = function(context, tag)
  local result = {}
  for generic in context.iter(context.generics) do
    local name = context["get-text"](generic.entry.name)
    table.insert(
      result,
      module.__build(" * @", tag, " ", name, " ", { content = "The " .. name .. " type", mark = "tabstop" })
    )
  end
  return result
end
