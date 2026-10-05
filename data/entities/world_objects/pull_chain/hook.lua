local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()
  entity:set_traversable_by(false)
  entity:set_drawn_in_y_order(true)

  entity.caught_objects = {}

  entity:add_collision_test("center", function(entity, other)
    if (other:get_type() == "custom_entity") and (other.pull_chain_handle_can_be_caught == true) then
      entity:catch_handle(other)
    end
  end)

  --Attack to push block:
  --NOTE: This isn't working for some reason. The hook/block combo can be pulled, but not pushed. The block is... blocked by the hook somehow
  if entity:get_property("attached_block") then
    entity:attach_to_block(map:get_entity(entity:get_property("attached_block")))
  end

  if entity:get_property("can_be_pushed") then
    entity.can_be_pushed = true
  end
end


function entity:catch_handle(handle)
  sol.audio.play_sound("impact_metal")
  local x, y, z = entity:get_position()
  handle:set_position(x, y, z)
  handle:stop_movement()
  entity.caught_objects[#entity.caught_objects + 1] = handle
end


function entity:attach_to_block(block)
  entity:set_traversable_by("block", true)
  entity:set_can_traverse("block", true)
  function block:on_moving()
    local m = block:get_movement()
    function m:on_position_changed()
      entity:set_position(block:get_position())
    end
  end
end


function entity:on_interaction()
  local hero = map:get_hero()
  if entity.caught_objects[1] then
    local handle = entity.caught_objects[#entity.caught_objects]
    sol.audio.play_sound("impact_metal")
    handle.pull_chain_handle_can_be_caught = false
    sol.timer.start(map, 2000, function()
      handle.pull_chain_handle_can_be_caught = true
    end)
    entity.caught_objects[#entity.caught_objects] = nil
    table.remove(entity.caught_objects, #entity.caught_objects)
    handle:start_carried(hero)

  elseif entity.can_be_pushed then
    local angle = hero:get_direction4_to(entity) * (math.pi / 2)
    local m = sol.movement.create"straight"
    m:set_angle(angle)
    m:set_max_distance(16)
    m:start(entity)
    entity:make_sound("hero_pushes", 20)
    --sol.audio.play_sound("hero_pushes")
  end
end

