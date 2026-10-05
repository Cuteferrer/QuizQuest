local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local sprite

function entity:on_created()
  sprite = entity:get_sprite()
  local width, height = sprite:get_size()
  entity:set_drawn_in_y_order(true)
  entity:set_size(width, 16)
  entity:set_origin(width/2, 13)
  entity:set_traversable_by(false)
  entity:set_traversable_by("hero", false)
  entity:set_traversable_by("enemy", false)
end



function entity:open()
  sol.audio.play_sound("door_open")
  sprite:set_animation("opening", function()
    if sprite:has_animation("open") then
      sprite:set_animation"open"
    else
      entity:remove()
    end
  entity:set_traversable_by(true)
  entity:set_traversable_by("hero", true)
  entity:set_traversable_by("enemy", true)
  end)
end


function entity:on_interaction()
  entity:open()
end

