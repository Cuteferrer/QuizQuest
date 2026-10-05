local sensor_meta = sol.main.get_metatable"sensor"

sensor_meta:register_event("on_activated", function(self)
  local sensor = self
  local map = self:get_map()
  local game = self:get_game()

  --Open / close doors
  local open_doors_prefix = self:get_property("open_doors_prefix")
  if open_doors_prefix then
    map:open_doors(open_doors_prefix)
    self:remove()
  end
  local close_doors_prefix = self:get_property("close_doors_prefix")
  if close_doors_prefix then
    map:close_doors(close_doors_prefix)
    self:remove()
  end

  --Layer Up
  if sensor:get_property("layer_up") then
    local hero = map:get_hero()
    hero:set_layer(hero:get_layer() + 1)
  end

  if sensor:get_property("layer_down") then
    local hero = map:get_hero()
    hero:set_layer(hero:get_layer() - 1)
  end

  --Save solid ground
  if sensor:get_property("save_solid_ground") then
    local hero = map:get_hero()
    hero:save_solid_ground(hero:get_position())
  end

  --Reset solid ground
  if sensor:get_property("reset_solid_ground") then
    local hero = map:get_hero()
    hero:reset_solid_ground()
  end
end)

