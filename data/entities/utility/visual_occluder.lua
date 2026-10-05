local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local sprite

local check_frequency = 200
local hero_overlap_w, hero_overlap_h = 48, 48

function entity:on_created()
  local hero = map:get_hero()
  entity.target_opacity = 0
  entity.hidden = false
  --Permanant unhidden option:
  entity.stay_unhidden = entity:get_property("stay_unhidden")
  local x, y, z = entity:get_position()
  entity.unhidden_savegame_value = map:get_id():gsub("/", "_") .. "_visual_occluder_" .. x .. "_" .. y .. "_" .. z .. "_state"
  if game:get_value(entity.unhidden_savegame_value) then
    entity:remove()
    return
  end
  --Replace sprite:
  sprite = entity:get_sprite()
  if sprite then
    entity:remove_sprite(sprite)
  end
  sprite = entity:create_sprite"utility/box_off_black"

  --Hide when hero overlaps:
  sol.timer.start(entity, 0, function()
    local x, y, z = hero:get_position()
    local overlaps = entity:overlaps(x - hero_overlap_w / 2, y - (hero_overlap_h / 2 - 8), hero_overlap_w, hero_overlap_h)
    --If permanant unhide:
    if overlaps and entity.stay_unhidden then
      entity:fade(-1)
      game:set_value(entity.unhidden_savegame_value, true)
      return false
    --Not hidden, overlapping -> go transparent
    elseif not entity.hidden and overlaps then
      entity:fade(-1)
    --Not hidden, not overlapping -> go back opaque
    elseif not entity.hidden and not overlaps and entity:get_sprite():get_opacity() < 255 then
      entity:fade(1)
    --Hidden, but not overlapping -> go back opaque
    elseif entity.hidden and not overlaps then
      entity.hidden = false
      entity:fade(1)
    end
    return check_frequency
  end)
end


function entity:fade(step)
  sol.timer.start(10, function()
    local opacity = sprite:get_opacity()
    if (step == -1) and opacity <= entity.target_opacity then
      entity.hidden = true
    elseif (step == -1) and opacity > entity.target_opacity then
      sprite:set_opacity(opacity - 5)
      return true
    elseif step == 1 and opacity < 255 then
      sprite:set_opacity(math.min(opacity + 5, 255))
      return true
    end
  end)
end


function entity:hide()
  sol.timer.stop_all(entity)
  entity:fade(-1)
  if entity.stay_unhidden then
    game:set_value(entity.unhidden_savegame_value, true)
  end
end

