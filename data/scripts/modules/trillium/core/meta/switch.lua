local switch_meta = sol.main.get_metatable"switch"


switch_meta:register_event("on_activated", function(self)
  local switch = self
  local map = self:get_map()

  local door_prefix = switch:get_property("door_prefix")
  if door_prefix then
    map:open_doors(door_prefix)
  end

end)


--Activate/Deactivate: replicate activation/deactivation from code
function switch_meta:activate(entity)
  local switch = self
  self:set_activated(true)
  sol.audio.play_sound("switch")
  if self.on_activated then self:on_activated(entity) end
end

function switch_meta:deactivate(entity)
  local switch = self
  self:set_activated(false)
  sol.audio.play_sound("switch")
  if self.on_inactivated then self:on_inactivated(entity) end
end



function switch_meta:toggle()
  local switch = self
  if not switch:is_activated() then
    sol.audio.play_sound("switch")
    switch:set_activated(true)
    switch:on_activated()
  else
    sol.audio.play_sound("switch")
    switch:set_activated(false)
    if switch.on_inactivated then switch:on_inactivated() end
  end
end


switch_meta:register_event("on_created", function(switch)
  --Create an interactable entity on top of solid switches so you can use the action button instead of needing to use a sword or whatever:
  if not switch:is_walkable() then
    local map = switch:get_map()
    local x, y, z = switch:get_position()
    local width, height = switch:get_size()
    local entity = map:create_custom_entity{
      x = x, y = y, layer = z, width = width, height = height, direction = 0,
    }
    entity:set_origin(switch:get_origin())

    function entity:on_interaction()
      switch:toggle()
    end
  end
end)


