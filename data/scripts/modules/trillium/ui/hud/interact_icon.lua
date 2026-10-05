local interact_icon_builder = {}

function interact_icon_builder:new(game, config)
  local icon  = {}
  icon.x = config.x
  icon.y = config.y

  local icon_surface = sol.surface.create(48, 16)
  icon_surface:set_opacity(0)
  local icon_box = sol.surface.create("hud/interact_icon.png") --currently unused
  icon_box:set_opacity(0)

  local controls = sol.controls.get_main_controls()
  local controls_manager = sol.controls.get_controls_manager()

  local function check()
    local effect
    --Recreate the button sprite, since the player may have changed input types:
    local button_sprite_id, button_animation = controls_manager:get_command_sprite_id("action")
    local button_sprite = sol.sprite.create(button_sprite_id)
    button_sprite:set_animation(button_animation)
    local icon_x, icon_y = button_sprite:get_origin() --16, 13

    --Figure out if there's an active effect for the action button:
    local hero = game:get_hero()
    local facing_entity = hero:get_facing_entity()
    if facing_entity then
      local should_show = false
      if type(facing_entity.show_interact_icon) == "function" then
        should_show = facing_entity:show_interact_icon(hero)
      elseif facing_entity.show_interact_icon then
        should_show = true
      elseif facing_entity.on_interaction then
        should_show = true
      end
      if should_show then
        effect = "interact"
        icon.target = facing_entity --TODO: if you set this, the icon will jump away from the facing entity to the hero too quick
      end
    else
      icon.target = nil
      game:get_command_effect("action")
    end
    if effect == "speak" then effect = "interact"
    elseif effect == "swim" then effect = nil
    end
    --If the active effect isn't the same as it was last time we checked, 
    if effect ~= icon.current_text then
      icon.current_text = effect
        icon_surface:clear()

      if effect == nil then
        icon_surface:fade_out(5)
      else
        icon_surface:fade_in(5)
        icon_box:set_opacity(255) --don't make opaque until now otherwise you get 1 fame visible as game starts
      end
      --icon_box:draw(icon_surface)
      button_sprite:draw(icon_surface, icon_x, icon_y)
    end
    return true
  end


  function icon:on_draw(dst)
    local target = icon.target
    if not target then return end
    local x, y = target:get_position()
    local camera = sol.main.get_game():get_map():get_camera()
    if not camera then return end
    local camx, camy = camera:get_position()
    x = x - camx
    y = y - camy - 32
    icon.x, icon.y = x, y
    icon_surface:draw(dst, icon.x, icon.y)
  end

  function icon:on_started()
    icon_surface:set_opacity(0)
    sol.timer.start(icon, 100, check)
  end

  return icon
end

return interact_icon_builder