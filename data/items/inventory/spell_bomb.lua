local item = ...
local game = item:get_game()

local magic_cost = 45
local windup_time = 500
local winddown_time = 500

function item:on_started()
  local savegame_variable = "possession_spell_bomb"
  item:set_savegame_variable(savegame_variable)
  item:set_assignable(true)
  item:set_ammo("_magic")
end
 

function item:on_using()
  local hero = game:get_hero()
  local map = game:get_map()
  if not item:try_spend_ammo(magic_cost) then
    hero:unfreeze()
    item:set_finished()
    return
  end
  hero:set_animation("punch_windup")
  sol.audio.play_sound"finger_snap"
  sol.timer.start(hero, windup_time, function()
    sol.timer.start(hero, winddown_time, function()
      hero:unfreeze()
      item:set_finished()
    end)

    local x, y, z = hero:get_position()
    local direction = hero:get_direction()
    local offset = 48
    sol.audio.play_sound"door_open"
    local charge = map:create_custom_entity{
      x = x + game:dx(offset)[direction],
      y = y + game:dy(offset)[direction],
      layer = z,
      width = 16, height = 16, direction = 0,
      sprite = "items/implosion_charge",
    }
    local charge_sprite = charge:get_sprite()
    function charge_sprite:on_animation_finished()
      x, y, z = charge:get_position()
      map:create_explosion{
        x = x, y = y - 12, layer = z,
      }
      sol.audio.play_sound("explosion")
    end
  end)
end
