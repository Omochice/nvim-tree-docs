-- Core internal functionality for nvim-tree-docs
-- Handles documentation generation, collection, and editing

local M = {}

-- Module dependencies
local utils = require("nvim-tree-docs.utils")
local templates = require("nvim-tree-docs.template")
local collectors = require("nvim-tree-docs.collector")
local editing = require("nvim-tree-docs.editing")
local configure = require("nvim-tree-docs.configure")
local queries = require("nvim-treesitter.query")

-- Language specifications mapping
local language_specs = {
  javascript = "jsdoc",
  lua = "luadoc",
  typescript = "tsdoc",
}

--- Cache for documentation data to avoid recomputation
local doc_cache = {}

--- Get the documentation spec name for a given language
--- @param lang string: The language name (e.g., 'javascript', 'lua')
--- @return string: The spec name (e.g., 'jsdoc', 'luadoc')
function M.get_spec_for_lang(lang)
  local spec = language_specs[lang]
  if not spec then
    error(string.format("No language spec configured for %s", lang))
  end
  return spec
end

--- Get the complete configuration for a language spec
--- @param lang string: The language name
--- @param spec string: The spec name
--- @return table: The merged configuration
function M.get_spec_config(lang, spec)
  local spec_def = templates.get_spec(lang, spec)
  local module_config = configure.get()
  local spec_default_config = spec_def.config
  local lang_config = utils.get({ "lang_config", lang, spec }, module_config, {})
  local spec_config = utils.get({ "spec_config", spec }, module_config, {})
  return vim.tbl_deep_extend("force", spec_default_config, spec_config, lang_config)
end

--- Get the documentation spec for a buffer
--- @param bufnr number?: The buffer number (defaults to current buffer)
--- @return string: The spec name
function M.get_spec_for_buf(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  return M.get_spec_for_lang(vim.api.nvim_buf_get_option(bufnr, "ft"))
end

--- Generate documentation for a list of documentation data
--- @param data_list table: List of documentation data entries
--- @param bufnr number?: Buffer number (defaults to current buffer)
--- @param lang string?: Language override (defaults to buffer filetype)
--- @return boolean: Success status
function M.generate_docs(data_list, bufnr, lang)
  bufnr = utils.get_bufnr(bufnr)
  lang = lang or vim.api.nvim_buf_get_option(bufnr, "ft")
  local spec_name = M.get_spec_for_lang(lang)
  local spec = templates.get_spec(lang, spec_name)
  local spec_config = M.get_spec_config(lang, spec_name)
  local edits = {}
  local marks = {}

  -- Sort data from top to bottom to ensure proper line offset calculation
  table.sort(data_list, function(a, b)
    local _, _, start_byte_a = utils.get_start_position(a)
    local _, _, start_byte_b = utils.get_start_position(b)
    return start_byte_a < start_byte_b
  end)

  local line_offset = 0
  for _, doc_data in ipairs(data_list) do
    local node_sr, node_sc = utils.get_start_position(doc_data)
    local node_er, node_ec = utils.get_end_position(doc_data)
    local content_lines = utils.get_buf_content(node_sr, node_sc, node_er, node_ec, bufnr)
    local replaced_count = (node_er + 1) - node_sr

    local result = templates.process_template(doc_data, {
      spec = spec,
      bufnr = bufnr,
      config = spec_config,
      ["start-line"] = node_sr + line_offset,
      ["start-col"] = node_sc,
      kind = doc_data.kind,
      content = content_lines,
    })

    table.insert(edits, {
      newText = table.concat(result.content, "\n") .. "\n",
      range = {
        start = { line = node_sr, character = 0 },
        ["end"] = { line = node_er + 1, character = 0 },
      },
    })

    vim.list_extend(marks, result.marks)
    line_offset = line_offset + #result.content - replaced_count
  end

  return vim.lsp.util.apply_text_edits(edits, bufnr, "utf-16")
end

--- Collect all documentation data from a buffer
--- @param bufnr number?: Buffer number (defaults to current buffer)
--- @return table: Collector containing documentation data
function M.collect_docs(bufnr)
  bufnr = utils.get_bufnr(bufnr)

  -- Return cached data if buffer hasn't changed
  if utils.get({ bufnr, "tick" }, doc_cache) == vim.api.nvim_buf_get_changedtick(bufnr) then
    return utils.get({ bufnr, "docs" }, doc_cache)
  end

  local collector = collectors.new_collector()
  local doc_matches = queries.collect_group_results(bufnr, "docs")

  for _, item in ipairs(doc_matches) do
    for kind, match in pairs(item) do
      collectors.add_match(collector, kind, match)
    end
  end

  doc_cache[bufnr] = {
    tick = vim.api.nvim_buf_get_changedtick(bufnr),
    docs = collector,
  }

  return collector
end

--- Get documentation data for a specific tree-sitter node
--- @param node table: Tree-sitter node
--- @param bufnr number?: Buffer number (defaults to current buffer)
--- @return table?: Documentation data if found
function M.get_doc_data_for_node(node, bufnr)
  local current = nil
  local last_start = nil
  local last_end = nil
  local doc_data = M.collect_docs(bufnr)
  local _, _, node_start = node:start()

  for iter_item in collectors.iterate_collector(doc_data) do
    local is_more_specific = true
    local doc_def = iter_item.entry
    local _, _, start = utils.get_start_position(doc_def)
    local _, _, end_pos = utils.get_end_position(doc_def)
    local is_in_range = (node_start >= start) and (node_start < end_pos)

    if last_start and last_end then
      is_more_specific = (start >= last_start) and (end_pos <= last_end)
    end

    if is_in_range and is_more_specific then
      last_start = start
      last_end = end_pos
      current = doc_def
    end
  end

  return current
end

--- Generate documentation for a specific node
--- @param node table: Tree-sitter node
--- @param bufnr number?: Buffer number
--- @param lang string?: Language override
--- @return boolean?: Success status if node exists
function M.doc_node(node, bufnr, lang)
  if node then
    local doc_data = M.get_doc_data_for_node(node, bufnr)
    return M.generate_docs({ doc_data }, bufnr, lang)
  end
  return nil
end

--- Generate documentation for the node at cursor position
--- @return boolean?: Success status
function M.doc_node_at_cursor()
  return M.doc_node(vim.treesitter.get_node())
end

--- Get documentation entries based on position criteria
--- @param args table: Arguments containing start-line, end-line, position, inclusion, bufnr
--- @return table: List of matching documentation entries
function M.get_docs_from_position(args)
  local start_line = args["start-line"]
  local end_line = args["end-line"]
  local position = args.position
  local inclusion = args.inclusion
  local bufnr = args.bufnr
  local is_edit_type = (position == "edit")
  local doc_data = M.collect_docs(bufnr)
  local result = {}

  for item in collectors.iterate_collector(doc_data) do
    local def = item.entry
    local start_r, end_r

    if is_edit_type then
      start_r = utils.get_edit_start_position(def)
      end_r = utils.get_edit_end_position(def)
    else
      start_r = utils.get_start_position(def)
      end_r = utils.get_end_position(def)
    end

    local matches
    if inclusion then
      matches = (start_line >= start_r) and (end_line <= end_r)
    else
      matches = (start_r >= start_line) and (end_r <= end_line)
    end

    if matches then
      table.insert(result, def)
    end
  end

  return result
end

--- Get documentation entries within a range
--- @param args table: Arguments with start-line, end-line, bufnr
--- @return table: List of documentation entries
function M.get_docs_in_range(args)
  return M.get_docs_from_position(vim.tbl_extend("force", args, {
    position = nil,
    inclusion = false,
  }))
end

--- Get documentation entries at a specific range for editing
--- @param args table: Arguments with start-line, end-line, bufnr
--- @return table: List of documentation entries
function M.get_docs_at_range(args)
  return M.get_docs_from_position(vim.tbl_extend("force", args, {
    inclusion = true,
    position = "edit",
  }))
end

--- Get documentation entries from current visual selection
--- @return table: List of documentation entries
function M.get_docs_from_selection()
  local _, start, _, _ = unpack(vim.fn.getpos("'<"))
  local _, end_pos, _, _ = unpack(vim.fn.getpos("'>"))
  return M.get_docs_in_range({
    ["start-line"] = start - 1,
    ["end-line"] = end_pos - 1,
  })
end

-- Generate documentation for all entries in current selection
-- @return boolean: Success status
function M.doc_all_in_range()
  return M.generate_docs(M.get_docs_from_selection())
end

--- Edit documentation at cursor position
--- @return boolean?: Success status if documentation exists
function M.edit_doc_at_cursor()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local doc_data = M.get_docs_at_range({
    ["start-line"] = row - 1,
    ["end-line"] = row - 1,
  })
  local bufnr = vim.api.nvim_get_current_buf()
  local lang = vim.api.nvim_buf_get_option(bufnr, "ft")
  local spec_name = M.get_spec_for_lang(lang)
  local spec = templates.get_spec(lang, spec_name)
  local doc_lang = spec["doc-lang"]
  local doc_entry = doc_data[1] and doc_data[1].doc

  if type(doc_entry) == "table" and doc_entry.node and doc_lang then
    return editing.edit_doc({
      lang = lang,
      ["spec-name"] = spec_name,
      bufnr = bufnr,
      ["doc-lang"] = doc_lang,
      node = doc_entry.node,
    })
  end
  return nil
end

local mappings = {
  { name = "doc_node_at_cursor", mode = "n", desc = "Document node at cursor", keymap = "gdd" },
  { name = "doc_all_in_range", mode = "v", desc = "Document all nodes in range", keymap = "gdd" },
  { name = "edit_doc_at_cursor", mode = "n", desc = "Edit documentation at cursor", keymap = "gde" },
}

--- Attach keymaps to a buffer
--- @param bufnr number?: Buffer number (defaults to current buffer)
function M.attach(bufnr)
  local bufnr = utils.get_bufnr(bufnr)
  local config = configure.get()
  for _, map in ipairs(mappings) do
    local map_name = string.format("<Plug>(nvim-tree-docs-%s)", map.name:gsub("_", "-"))
    vim.api.nvim_buf_set_keymap(
      bufnr,
      map.mode,
      map_name,
      string.format("<Cmd>lua require('nvim-tree-docs.internal').%s()<CR>", map.name),
      { noremap = true, desc = map.desc }
    )
    if not config.disable_default_mappings then
      vim.api.nvim_buf_set_keymap(bufnr, map.mode, map.keymap, map_name, { noremap = true, desc = map.desc })
    end
  end
end

--- Detach keymaps from a buffer
--- @param bufnr number?: Buffer number (defaults to current buffer)
function M.detach(bufnr)
  bufnr = utils.get_bufnr(bufnr)
  local config = configure.get()
  local k = vim:iter(vim.api.nvim_buf_get_keymap(bufnr, "nv"))
  for _, map in ipairs(mappings) do
    local lhs = string.format("<Plug>(nvim-tree-docs-%s)", map.name:gsub("_", "-"))
    if k:any(function(m)
      return m.mode == map.mode and m.lhs == lhs
    end) then
      vim.api.nvim_buf_del_keymap(
        bufnr,
        map.mode,
        string.format("<Plug>(nvim-tree-docs-%s)", map.name:gsub("_", "-"))
      )
    end
    if k:any(function(m)
      return m.mode == map.mode and m.lhs == map.keymap
    end) then
      vim.api.nvim_buf_del_keymap(
        bufnr,
        map.mode,
        map.keymap
      )
    end
  end
end

-- Export snake_case versions for configuration purposes
M.doc_node_at_cursor = M.doc_node_at_cursor
M.doc_node = M.doc_node
M.doc_all_in_range = M.doc_all_in_range
M.edit_doc_at_cursor = M.edit_doc_at_cursor

return M
