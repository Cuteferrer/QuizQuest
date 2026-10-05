--[[
Created by Max Mraz, licensed MIT

Gameover system, works with checkpoint system
When the player dies, they show a "dying" animation, then a "dead" animation, then they respawn at the last checkpoint.
--]]

local black = {}
local black_surface = sol.surface.create()
black_surface:fill_color{0,0,0}

function black:on_started()
  black_surface:set_opacity(0)
  black_surface:fade_in(2)
end

function black:on_draw(dst)
  black_surface:draw(dst)
end

local game_meta = sol.main.get_metatable"game"

local just_died = false

game_meta:register_event("on_started", function(game)
  local hero = game:get_hero()

  if not sol.menu.is_started(black) then
    sol.menu.start(game, black)
  end
  sol.timer.start(game, 1000, function()
    game:set_suspended(false)
    sol.menu.stop(black)
  end)
  game:respawn_at_checkpoint()
  if just_died then
    just_died = false
    sol.timer.start(game, 1000, function()
      game.event_manager:trigger_event("gameover_respawn")
    end)
  end
end)


game_meta:register_event("on_game_over_started", function(self)
  local game = self
  local map = game:get_map()
  local hero = game:get_hero()
  local x, y, z = hero:get_position()

  hero:set_visible(false)
  sol.audio.stop_music()
  local cam_surface = map:get_camera():get_surface()
  local dark_steps = 1
  local darkDelta = 3
  sol.timer.start(sol.main, 40, function()
    local rgb = cam_surface:get_color_modulation()
    cam_surface:set_color_modulation({math.max(rgb[1]-darkDelta, 0), math.max(rgb[2]-darkDelta, 0), math.max(rgb[3]-darkDelta, 0)})
    dark_steps = dark_steps + 1
    if dark_steps <= 20 then
      return true
    end
  end)

  local sprite_id = hero:get_sprite():get_animation_set()
  local dummy = map:create_custom_entity({
    x=x, y=y, layer=z, direction=0, width=16,height=16,
    sprite = sprite_id,
  })
  local sprite = dummy:get_sprite()
  sprite:set_ignore_suspend()
  sprite:set_animation("dying", function()
    sprite:set_animation"dead"
    sol.timer.start(game, 1000, function()
      sol.menu.start(sol.main, black)
      game:start()
    end)
  end)
end)
