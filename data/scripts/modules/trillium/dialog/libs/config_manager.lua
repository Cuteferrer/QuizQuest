local default_config = require("scripts/modules/trillium/dialog/configs/default_config")
local config_prefix = "scripts/modules/trillium/dialog/configs/"

local manager = {}


function manager:get_default_config()
  local config = {}
  for k, v in pairs(default_config) do
    config[k] = v
  end
  return config
end


function manager:load_config(menu, override_id)
  assert(sol.file.exists(config_prefix .. override_id .. ".lua"), "Error: invalid config file passed in dialog info table. Config file " .. config_prefix .. override_id .. "does not exist")
  local config = menu:get_config()
  local new_config = require(config_prefix .. override_id)
  for k, v in pairs(new_config) do
    config[k] = v
  end
end


return manager
