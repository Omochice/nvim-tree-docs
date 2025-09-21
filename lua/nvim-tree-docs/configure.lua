local default_config = {}
local config = {}

--- @alias SpecConfig { slots?: { [string]: boolean }, processors?: { [string]: fun(): string } }
--- @alias Option { spec_config?: { [string]: SpecConfig }}

--- @param user_config Option
function M.set(user_config)
  config = vim.tbl_deep_extend("force", default_config, user_config)
end

function M.get()
  return config
end
