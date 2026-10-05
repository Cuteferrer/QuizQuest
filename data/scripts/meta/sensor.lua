-- Provides additional features to the sensor type for this quest.

require("scripts/multi_events")

local sensor_meta = sol.main.get_metatable("sensor")

sensor_meta:register_event("on_activated_repeat", function(sensor)

  local hero = sensor:get_map():get_hero()
  local map = sensor:get_map()

  -- Sensors with a custom property called "open_house" automatically open an outside house door tile.
  local door_name = sensor:get_property("open_house")
  if door_name ~= nil then
    local door = map:get_entity(door_name)
    if door ~= nil then
      if hero:get_direction() == 1
	         and door:is_enabled() then
        door:set_enabled(false)
        sol.audio.play_sound("door_open")
      end
    end
  end
end)
