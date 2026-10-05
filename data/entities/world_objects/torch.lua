local entity = ...
local game = entity:get_game()
local map = entity:get_map()

local torch_light_sprite = sol.sprite.create("entities/effects/light_m")

function entity:on_created()
  local sprite = entity:get_sprite()
  sprite:set_animation("unlit")
  entity:set_drawn_in_y_order(true)
  entity:set_traversable_by(false)

  --if it starts lit:
  if entity:get_property("initial_state") == "lit" then
    entity:set_lit(true)
  end
end

function entity:react_to_fire()
  entity:light()
end


function entity:is_lit()
  return entity.lit or false
end


--Silently sets torch as lit, won't trigger door events:
function entity:set_lit(should_be_lit)
  local sprite = entity:get_sprite()
  sprite:set_animation(should_be_lit and "lit" or "unlit")
  entity.lit = should_be_lit
  --[[
  if should_be_lit then
    entity:set_property("lighting_effect_type", "torch")
  else
    entity:set_property("lighting_effect_type", nil)
  end
  --]]

  if should_be_lit then
    if entity.light_source then map:unregister_light_source(entity.light_source) end --unregister any old light source
    sol.timer.start(entity, 10, function()
      entity.light_source = map:add_dynamic_light_source(entity, torch_light_sprite)
    end)
  else
    if entity.light_source then map:unregister_light_source(entity.light_source) end
  end
end


function entity:light()
  local torch_group = entity:get_property("torch_group")

  entity:set_lit(true)

  local full_group_lit = true
  for t in map:get_entities_by_type("custom_entity") do
    if (t:get_model() == "world_objects/torch") and (t:get_property("torch_group") == torch_group) and (t:is_lit() == false) then
      full_group_lit = false
      break
    end
  end
  if full_group_lit then
    map:open_doors(torch_group)
    if map.on_torch_group_lit then
      map:on_torch_group_lit(torch_group, entity)
    end
  end

  if map.on_torch_lit then
    map:on_torch_lit(torch_group, entity)
  end

  --TODO: create smolder entity??
end


function entity:toggle_lit()
  if entity.lit then
    entity:set_lit(false)
  else
    entity:light()
  end
end

