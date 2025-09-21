-- Template processing module for nvim-tree-docs
-- Handles template expansion, processing, and documentation generation

local M = {}

-- Module dependencies
local utils = require("nvim-tree-docs.utils")
local collectors = require("nvim-tree-docs.collector")

-- Storage for loaded language specifications
local loaded_specs = {}
M.loaded_specs = loaded_specs -- Expose for registration by specs

-- Helper functions to replace Aniseed core functions
local function is_table(v)
  return type(v) == "table"
end

--- Get text content from a tree-sitter node
--- @param context table: Template context
--- @param node table?: Tree-sitter node or node wrapper
--- @param default string?: Default value if node is empty
--- @param multi boolean?: Whether to return multiple lines
--- @return string|table: Text content or default value
function M.get_text(context, node, default, multi)
  local default_value = default or ""
  if node and is_table(node) then
    local tsnode = node.node or node
    local bufnr = context.bufnr or vim.api.nvim_get_current_buf()
    local text = vim.treesitter.get_node_text(tsnode, bufnr)
    if multi then
      return vim.split(text, "\n", { plain = true })
    else
      local lines = vim.split(text, "\n", { plain = true })
      local line = lines[1]
      if line and line ~= "" then
        return line
      else
        return default_value
      end
    end
  else
    return default_value
  end
end

--- Create an iterator for a collector
--- @param collector table?: Collector to iterate over
--- @return function: Iterator function
function M.iter(collector)
  if collector then
    return collectors.iterate_collector(collector)
  else
    return function()
      return nil
    end
  end
end

--- Get configuration value from context
--- @param context table: Template context
--- @param path table|string: Path to configuration value
--- @param default any?: Default value
--- @return any: Configuration value or default
function M.conf(context, path, default)
  return utils.get(path, context.config, default)
end

--- Check if collector is empty
--- @param collector table?: Collector to check
--- @return boolean: True if empty
function M.empty(collector)
  return collectors.is_collector_empty(collector)
end

--- Build a line with content and marks
--- @param ... any: Content pieces (strings or mark objects)
--- @return table: Line object with content and marks
function M.build_line(...)
  local result = { content = "", marks = {} }
  local function add_content(text)
    result.content = result.content .. text
  end

  for _, value in ipairs({ ... }) do
    if type(value) == "string" then
      --- @cast value string
      add_content(value)
    elseif is_table(value) and type(value.content) == "string" then
      --- @cast value { content: string, mark: string? }
      if value.mark then
        local start = #result.content
        add_content(value.content)
        table.insert(result.marks, {
          kind = value.mark,
          stop = #value.content + start,
          start = start,
        })
      else
        add_content(value.content)
      end
    end
  end
  return result
end

--- Create a new template context
--- @param collector table?: Collector with data
--- @param options table?: Context options
--- @return table: Template context
function M.new_template_context(collector, options)
  options = options or {}
  local context = vim.tbl_extend("keep", {
    iter = M.iter,
    ["empty?"] = M.empty,
    build = M.build_line,
    config = options.config,
    kind = options.kind,
    ["start-line"] = options["start-line"] or 0,
    ["start-col"] = options["start-col"] or 0,
    content = options.content or {},
    bufnr = utils.get_bufnr(options.bufnr),
  }, collector or {})

  context["get-text"] = function(...)
    return M.get_text(context, ...)
  end
  context.conf = function(...)
    return M.conf(context, ...)
  end
  return context
end

--- Get a language specification
--- @param lang string: Language name
--- @param spec string: Spec name
--- @return table: Language specification
function M.get_spec(lang, spec)
  local key = lang .. "." .. spec
  if not loaded_specs[key] then
    require(string.format("nvim-tree-docs.specs.%s.%s", lang, spec))
  end
  return loaded_specs[key]
end

--- Normalize processor to ensure it has proper structure
--- @param processor function|table: Processor to normalize
--- @return table: Normalized processor
local function normalize_processor(processor)
  if vim.is_callable(processor) then
    --- @cast processor function
    return { build = processor }
  else
    --- @cast processor table
    return processor
  end
end

--- Get processor by name with alias resolution
--- @param processors table: Available processors
--- @param name string: Processor name
--- @param aliased_from string?: Original name if this is an alias
--- @return table: Processor info
local function get_processor(processors, name, aliased_from)
  local processor_config = processors[name]
  if type(processor_config) == "string" then
    --- @cast processor_config string
    return get_processor(processors, processor_config, aliased_from or name)
  else
    local result = normalize_processor(processor_config or processors.__default)
    return {
      processor = result,
      name = name,
      ["aliased-from"] = aliased_from,
    }
  end
end

--- Expand slots that have expand functions
--- @param ps_list table: Processor slot list
--- @param slot_config table: Slot configuration
--- @param processors table: Available processors
--- @return table: Expanded slot list
function M.get_expanded_slots(ps_list, slot_config, processors)
  local result = { unpack(ps_list) }
  local i = 1
  while i <= #result do
    local ps_name = result[i]
    local proc_info = get_processor(processors, ps_name)
    local processor = proc_info.processor
    if processor and processor.expand then
      local expanded = processor.expand(utils.make_inverse_list(result), slot_config)
      table.remove(result, i)
      for j, expanded_ps in ipairs(expanded) do
        table.insert(result, i + j - 1, expanded_ps)
      end
    end
    i = i + 1
  end
  return result
end

--- Filter slots based on configuration and conditions
--- @param ps_list table: Processor slot list
--- @param processors table: Available processors
--- @param slot_config table: Slot configuration
--- @param context table: Template context
--- @return table: Filtered slot list
function M.get_filtered_slots(ps_list, processors, slot_config, context)
  return vim
    .iter(ps_list)
    :map(function(name)
      return get_processor(processors, name)
    end)
    :filter(function(proc_info)
      return proc_info.processor
        and (proc_info.processor.implicit or slot_config[proc_info["aliased-from"] or proc_info.name])
    end)
    :map(function(proc_info)
      local include_ps
      if utils.method(proc_info.processor, "when") then
        include_ps = proc_info.processor.when(context)
      else
        include_ps = is_table(proc_info.processor)
      end
      return include_ps and proc_info.name or nil
    end)
    :totable()
end

--- Normalize build output to consistent format
--- @param output any: Build output
--- @return table: Normalized output
function M.normalize_build_output(output)
  if type(output) == "string" then
    return { { content = output, marks = {} } }
  elseif is_table(output) then
    if type(output.content) == "string" then
      --- @cast output { content: string }
      return { output }
    else
      return vim
        .iter(output)
        :map(function(item)
          return type(item) == "string" and { content = item, marks = {} } or item
        end)
        :totable()
    end
  end
  return {}
end

--- Apply indentation to lines
--- @param lines table: Lines to indent
--- @param indenter function|nil: Indenter function
--- @param context table: Template context
--- @return table: Indented lines
function M.indent_lines(lines, indenter, context)
  local indentation_amount
  if vim.is_callable(indenter) then
    --- @cast indenter function
    indentation_amount = indenter(lines, context)
  else
    indentation_amount = context["start-col"]
  end

  return vim
    .iter(lines)
    :map(function(line)
      return vim.tbl_extend("force", {}, {
        content = string.rep(" ", indentation_amount) .. line.content,
        marks = vim
          .iter(line.marks)
          :map(function(mark)
            return vim.tbl_extend("force", mark, {
              start = mark.start + indentation_amount,
              stop = mark.stop + indentation_amount,
            })
          end)
          :totable(),
      })
    end)
    :totable()
end

--- Build slots using processors
--- @param ps_list table: Processor slot list
--- @param processors table: Available processors
--- @param context table: Template context
--- @return table: Built output
function M.build_slots(ps_list, processors, context)
  local result = {}
  for i, ps_name in ipairs(ps_list) do
    local proc_info = get_processor(processors, ps_name)
    local processor = proc_info.processor
    local default_processor = processors.__default
    local build_fn = (processor and processor.build) or (default_processor and default_processor.build)
    local indent_fn = (processor and processor.indent) or (default_processor and default_processor.indent)

    local slot_result
    if vim.is_callable(build_fn) then
      --- @cast build_fn function
      slot_result = M.indent_lines(
        M.normalize_build_output(build_fn(context, {
          processors = ps_list,
          index = i,
          name = ps_name,
        })),
        indent_fn,
        context
      )
    else
      slot_result = {}
    end
    table.insert(result, slot_result)
  end
  return result
end

--- Convert output to lines
--- @param output table: Build output
--- @return table: Flattened lines
function M.output_to_lines(output)
  return vim
    .iter(output)
    :fold({}, function(acc, entry)
      vim.list_extend(acc, entry)
      return acc
    end)
    :totable()
end

--- Package build output with line numbers
--- @param output table: Build output
--- @param context table: Template context
--- @return table: Packaged output with content and marks
function M.package_build_output(output, context)
  local result = { content = {}, marks = {} }
  for i, entry in ipairs(output) do
    for j, line in ipairs(entry) do
      local lnum = #result.content + 1
      table.insert(result.content, line.content)
      vim.list_extend(
        result.marks,
        vim
          .iter(line.marks)
          :map(function(mark)
            return vim.tbl_extend("force", {}, mark, {
              line = lnum + (context["start-line"] or 0),
            })
          end)
          :totable()
      )
    end
  end
  return result
end

--- Process a template with given collector and configuration
--- @param collector table: Data collector
--- @param config table: Processing configuration
--- @return table: Processed template output
function M.process_template(collector, config)
  local spec = config.spec
  local kind = config.kind
  local spec_conf = config.config

  local ps_list = (spec_conf.templates and spec_conf.templates[kind]) or spec.templates[kind]
  local processors = vim.tbl_extend("force", spec.processors, spec_conf.processors or {})
  local slot_config = (spec_conf.slots and spec_conf.slots[kind]) or {}
  local context = M.new_template_context(collector, config)

  return M.package_build_output(
    M.build_slots(
      M.get_filtered_slots(M.get_expanded_slots(ps_list, slot_config, processors), processors, slot_config, context),
      processors,
      context
    ),
    context
  )
end

--- Extend a specification with another specification's features
--- @param mod table: Module to extend
--- @param spec string?: Specification to extend from
function M.extend_spec(mod, spec)
  if spec and mod.module ~= spec then
    require("nvim-tree-docs.specs." .. spec)
    local inherited_spec = loaded_specs[spec]
    mod.templates = vim.tbl_extend("force", mod.templates, inherited_spec.templates)
    mod.utils = vim.tbl_extend("force", mod.utils, inherited_spec.utils)
    mod.inherits = inherited_spec
    mod.processors = vim.tbl_extend("force", mod.processors, inherited_spec.processors)
    mod.config = vim.tbl_deep_extend("force", inherited_spec.config, mod.config)
  end
end

return M
