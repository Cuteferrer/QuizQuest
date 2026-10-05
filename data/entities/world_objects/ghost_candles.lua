local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local sprite

function entity:on_created()
  local ghost_exists = game:get_value("blood_ghost_exists")
  sprite = entity:get_sprite()
  sprite:set_animation(ghost_exists and "lit" or "unlit")
  entity:set_drawn_in_y_order(true)
  entity:set_traversable_by(false)

  if sprite:get_animation() == "lit" then
    entity:set_property("lighting_effect_type", "torch")
  end
end



local function summon_ghost()
  map:remove_blood_ghost()
  entity.on_interaction = nil

  local hero = map:get_hero()
  hero:freeze()
  hero:set_animation"walking"
  local m = sol.movement.create"straight"
  m:set_angle(entity:get_angle(hero))
  m:set_speed(40)
  m:set_max_distance(32)
  m:start(hero, function()
    hero:set_animation"stopped"
    hero:unfreeze()
  end)
  m.on_obstacle_reached = function()
    hero:set_animation"stopped"
    hero:unfreeze()
  end

  local x, y, z = entity:get_position()
  local magic_circle = map:create_custom_entity{
    x=x, y=y, layer=z, width=16, height=16, direction=0,
    sprite = "items/ghost_magic_circle",
  }
  magic_circle:get_sprite():set_animation("summoning")
  magic_circle:get_sprite():fade_out(100)

  sprite:set_animation("burning_out", function()
    map:create_poof(x, y, z)
    map:create_blood_ghost(x, y, z)
    entity:remove()
  end)
end


function entity:on_interaction()
  local ghost_exists = game:get_value("blood_ghost_exists")
  local eggs = game:get_item("consumables/ghost_seed")
  if not ghost_exists then
    game:start_dialog("world_objects.ghost_candles.no_ghost")
  elseif eggs:get_amount() < 1 then
    game:start_dialog("world_objects.ghost_candles.no_seeds")
  else
    game:start_dialog("world_objects.ghost_candles.seed_question", function(answer)
      if answer == 1 then
        summon_ghost()
        eggs:remove_amount(1)
      end
    end)
  end

end

