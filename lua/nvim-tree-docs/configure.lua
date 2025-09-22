local M = {}

--- @alias SpecConfig { slots?: { [string]: boolean }, processors?: { [string]: fun(): string | string[] } }
--- @alias LangConfig { [string]: SpecConfig }
--- @alias Option {lang_config?: {[string]: LangConfig }, spec_config?: { [string]: SpecConfig },  disable_default_mappings: boolean }

--- @type Option
local config = {}

--- @type Option
local default_config = {
  disable_default_mappings = false,
}

--- Set user config
--- @param user_config Option
function M.set(user_config)
  config = vim.tbl_deep_extend("force", default_config, user_config)
end

--- Get read-only config
--- @return Option
function M.get()
  return vim.deepcopy(config)
end

return M
