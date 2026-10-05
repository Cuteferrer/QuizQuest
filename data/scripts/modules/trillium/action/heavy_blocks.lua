--[[
Created by Max Mraz, licensed MIT

Gives blocks a "push_weight" and "lift_weight" property,
idea is for the player to find Power Bracelet-like items that allow them to push/lift heavy objects
--]]

local block_meta = sol.main.get_metatable"block"
local map_meta = sol.main.get_metatable"map"


block_meta:register_event("on_created", function(block)
  block:evaluate_weight()

end)


block_meta:register_event("on_moving", function(block)
  local game = block:get_game()
  local hero = game:get_hero()

end)


--Decide if the block can be pushed based on the hero's lift strength
function block_meta:evaluate_weight()
  local block = self
  local game = block:get_game()

  local push_weight = block:get_property("push_weight")
  if push_weight then
    push_weight = tonumber(push_weight)
    local can_do = game:get_ability("lift") >= push_weight
    block:set_pushable(can_do)
    block:set_pullable(can_do)
  end

  local lift_weight = block:get_property("lift_weight")
  if lift_weight then
    lift_weight = tonumber(lift_weight)
    block:make_liftable(lift_weight)
  end
end


function block_meta:make_liftable(weight)
  --Make blocks liftable (by giving them a "lift_weight") property
  local block = self
  local map = block:get_map()
  local lift_weight = block:get_property("lift_weight")
  if lift_weight then
    lift_weight = tonumber(lift_weight)
    block:set_weight(lift_weight)
  end

  --This would make the block land, so you could  keep pushing it and lifting it again
  --WARNING: this is still experimental
  --There have been observed bugs after lifting and tossing a block a couple times.
  --I would question whether you really NEED an entity that can be pushed early in the game, but lifted and tossed down elsewhere later
  --That might work better using a "world_objects/heavy_ball" entity to throw and pick back up, with a high weight. If not though, idk, debug this
  --[[
  function block:on_lifting(hero, carried_object)
    function carried_object:on_breaking()
      local x, y, z = carried_object:get_position()
      local new_block = map:create_block({
        x=x, y=y, layer=z,
        sprite = block:get_sprite():get_animation_set(),
        pushable = block:is_pushable(),
        pullable = block:is_pullable(),
        properties = {
          {key = "push_weight", value = block:get_property("push_weight")},
          {key = "lift_weight", value = block:get_property("lift_weight")},
        },
      })
      new_block:snap_to_grid()
    end
  end
  --]]
end


-- Make all blocks on the map check if they can be lifted
-- needs to be called when the hero gets a lifting upgrade, since blocks on the current map might now be able moveable when they were not before
function map_meta:reevaluate_block_weights()
  for block in self:get_entities_by_type("block") do
    block:evaluate_weight()
  end
end

