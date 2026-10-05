--Created by Max Mraz, licensed MIT
--System for imposing a limit on swimming. As player continues to swim, hero oxygen goes down. At 0, player drowns.
--Make sure to have an icon to be depleted in sprites/hud/swim_meter, set its origin to 0,0
--Also, you'll need an animation called "drowning_water"

--Setup:
--In initial game, you can set a different default max oxygen level with game:set_max_oxygen_level()

sol.modules.get_object("multi_events")
local manager = {}

local DEPLETION_RATE = 100 --how often LOSS_STEP of oxygen is removed, in ms
local depletion_rate_modifier = 1
local LOSS_STEP = 1 --how much (out of max_oxygen_level) oxygen points are removed
local RECOVERY_RATE = 10 --how many oxygen points recovered per 100ms when not swimming
local max_oxygen_level = 100

local hero_meta = sol.main.get_metatable"hero"
local game_meta = sol.main.get_metatable"game"

hero_meta:register_event("on_created", function(self)
  local hero = self
  local game = hero:get_game()
  max_oxygen_level = game:get_value("swimming_max_oxygen_level") or 100  
  hero.oxygen_level = max_oxygen_level
end)

--Sets max oxygen level for swimming. Default 100
function game_meta:set_max_oxygen_level(level)
  local game = self
  max_oxygen_level = level
  game:set_value("swimming_max_oxygen_level", level)
end

--Sets how quickly oxygen depletes while swimming, before you drown
function game_meta:set_oxygen_depletion_rate_modifier(new_mod)
  depletion_rate_modifier = new_mod
end

function game_meta:get_oxygen_depletion_rate_modifier()
  return depletion_rate_modifier
end


hero_meta:register_event("on_state_changed", function(self, new_state)
  if new_state == "swimming" then
    local hero = self
    if not sol.menu.is_started(manager:get_menu()) then
      sol.menu.start(sol.main.get_game(), manager:get_menu())
    end
    sol.timer.start(hero, DEPLETION_RATE * depletion_rate_modifier, function()
      if hero:get_state() == "swimming" then
        hero.oxygen_level = (hero.oxygen_level or 100) - LOSS_STEP
        if hero.oxygen_level <= 0 then hero:drown() end
        return true
      end
    end)
    --Stop burn status effect when you start swimming:
    if hero:is_status_effect_active("burn") then hero:stop_status_effect("burn") end

  else --state isn't "swimming"
    local hero = self
    sol.timer.start(hero, 100, function()
      hero.oxygen_level = (hero.oxygen_level or 100) + RECOVERY_RATE
      if hero.oxygen_level >= max_oxygen_level then
        hero.oxygen_level = max_oxygen_level
      else
        return true
      end
    end)
  end

end)

function hero_meta:drown()
  local hero = self
  hero:freeze()
  sol.audio.play_sound"swim"
  hero:set_invincible(true, 2000)
  hero:set_animation("drowning_water", function()
    sol.audio.play_sound"splash"
    hero:set_position(hero:get_solid_ground_position())
    hero:set_visible()
    hero:set_animation"stopped"
    hero:set_invincible(true, 500)
    hero:set_blinking(true, 400)
    hero:unfreeze()
  end)
end




--===========================================================================================================
-------------------------------------------------------------------------------------------------------------
--===========================================================================================================



local menu = {}
local ICON_SIZE = 8
menu.x = 380
menu.y = 220
local blob = sol.sprite.create("hud/swim_meter")
blob:set_animation"blob"
local ring = sol.sprite.create("hud/swim_meter")
ring:set_animation"ring"
local icon_surface = sol.surface.create(ICON_SIZE, ICON_SIZE)
local shadow = sol.sprite.create("hud/swim_meter")
shadow:set_animation"shadow"

function menu:on_started()
  local hero = sol.main.get_game():get_hero()
  menu.unneeded_count = 0
  blob:fade_in()
  ring:fade_in()

  sol.timer.start(menu, 100, function()
    menu.blob_height = ICON_SIZE * (hero.oxygen_level or 100) / max_oxygen_level

    if hero.oxygen_level == max_oxygen_level then
      menu.unneeded_count = menu.unneeded_count + 1
    else
      menu.unneeded_count = 0
    end

    if menu.unneeded_count > 8 and hero:get_state() ~= "swimming" then
      sol.menu.stop(menu)
    else
      return true
    end

  end)
end

function menu:on_draw(dst)
  local game = sol.main.get_game()
  local hero = game:get_hero()
  local camera = game:get_map():get_camera()
  local hx, hy, hz = hero:get_position()
  local cx, cy, cz = camera:get_position()
  icon_surface:clear()
  shadow:draw(icon_surface)
  blob:draw_region(0, ICON_SIZE - (menu.blob_height or ICON_SIZE), ICON_SIZE, ICON_SIZE, icon_surface)
  ring:draw(icon_surface)
  icon_surface:draw(dst, hx - cx + 8, hy - cy - 32)
end



function manager:get_menu()
  return menu
end

return manager
