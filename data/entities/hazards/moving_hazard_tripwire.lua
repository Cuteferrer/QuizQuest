--[[
By Max Mraz, licensed MIT

An entity that triggers a moving hazard, or multiple
Entity properties to set:
hazard (string): name of a moving_hazard map entity
hazards (string): comma separated list of names of moving_hazard map entities
--]]

local entity = ...
local game = entity:get_game()
local map = entity:get_map()


function entity:on_created()
  entity:activate()

  map:register_checkpoint_callback(entity, function(entity)
    entity:activate()
    entity:set_visible(true)
  end)
end


function entity:activate()
  entity.tripped = nil
  entity:add_collision_test("overlapping", function(entity, other)
    if entity.tripped then return end
    if other:get_type() ~= "hero" then return end
    --Trip so it can't be tripped again until its reset:
    entity.tripped = true
    entity:set_visible(false)
    --Get hazards or hazard, depending on property
    local hazards = {}
    if entity:get_property("hazards") then
      local names = {}
      for name in entity:get_property("hazards"):gmatch('([^,]+)') do
        table.insert(names, name)
      end
      for _, name in pairs(names) do
        assert(map:get_entity(name), "No entity found with name: " .. name)
        table.insert(hazards, map:get_entity(name))
      end
    --single hazard
    elseif entity:get_property("hazard") then
      local haz_string = entity:get_property"hazard"
      assert(map:get_entity(haz_string), "No entity found with name:" .. haz_string)
      hazards[1] = map:get_entity(haz_string)
    end

    --Send hazards
    local sound = entity:get_property"sound"
    if sound then sol.audio.play_sound(sound) end
    if entity:get_sprite() and entity:get_sprite():has_animation("activated") then
      entity:get_sprite():set_animation"activated"
    end
    for _, hazard in ipairs(hazards) do
      if hazard then
        hazard:go(hazard:get_direction() * math.pi / 2)
      end
    end
  end)

end

