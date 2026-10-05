local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()
  entity:set_drawn_in_y_order(true)
  entity:set_traversable_by(false)
  entity.drillspear_boost = true

end

function entity:react_to_drillspear()
  entity:shatter()
end


function entity:react_to_explosion(explosion)
  if explosion.demolishing then
    entity:shatter()
  end
end

function entity:shatter()
  if entity.shattered then return end
  entity.shattered = true
  entity:get_sprite():set_animation("breaking", function()
    entity:remove()
  end)
end
