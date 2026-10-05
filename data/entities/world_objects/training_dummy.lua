local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local font, font_size = sol.modules.get_object("language_manager"):get_menu_font()

local damage_display_duration = 1000


function entity:on_created()
  entity:set_traversable_by(false)
  entity:set_drawn_in_y_order(true)

  entity.number_surface = sol.text_surface.create{
    font = font, font_size = font_size,
    horizontal_alignment = "center",
  }
  local x, y, z = entity:get_position()
  entity.numbies_x , entity.numbies_y = x, y - 48
end


function entity:on_post_draw(dst)
  map:draw_visual(entity.number_surface, entity.numbies_x, entity.numbies_y)
end


function entity:process_hit(props)
  local damage = math.floor(props.damage)

  entity.displayed_damage = (entity.displayed_damage or 0) + damage
  entity.number_surface:set_text(entity.displayed_damage)
  entity.number_surface:set_opacity(255)
  if entity.damage_display_timer then entity.damage_display_timer:stop() end
  entity.damage_display_timer = sol.timer.start(entity, damage_display_duration, function()
    entity.displayed_damage = 0
    entity.number_surface:set_opacity(0)
  end)

  local sprite = entity:get_sprite()
  sprite:set_animation"shaking"
  if entity.shake_timer then entity.shake_timer:stop() end
  entity.shake_timer = sol.timer.start(entity, 800, function()
    sprite:set_animation"stopped"
  end)
  sol.sound.create("impact_metal"):play()
  sol.sound.create("impact_metal_2"):play()
  sol.sound.create("impact_wood_2"):play()
end



--Idk if this will cause problems, but pretend you're an enemy:
function entity:get_type()
  return "enemy"
end

function entity:get_attack_consequence()
  return 1
end

function entity:get_push_hero_on_sword()
  return false
end

function entity:get_life()
  return 999999
end

function entity:build_up_status_effect()
end

