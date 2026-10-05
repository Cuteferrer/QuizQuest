local entity = ...
local game = entity:get_game()
local map = entity:get_map()

local manager = require("scripts/modules/trillium/sound/sound_source_manager")

function entity:on_created()
  entity:set_visible(false)
  local sound_id = entity:get_property("sound_id")

  manager.init_map(map)
  manager.start_sound(map, sound_id)
end


