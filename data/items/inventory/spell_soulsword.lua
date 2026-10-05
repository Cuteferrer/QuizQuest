local item = ...
local game = item:get_game()

local magic_cost = 15
local damage = 10

-- Event called when the game is initialized.
item:register_event("on_started", function(self)
  item:set_savegame_variable("possession_spell_soulsword")
  item:set_assignable(true)
  item:set_ammo("_magic")
end)

item:register_event("on_using", function(self)
  if not item:try_spend_ammo(magic_cost) then
    item:set_finished()
    return
  end
  local map = item:get_map()
  local hero = game:get_hero()
  hero:set_animation("sword_windup")

  local x, y, z = hero:get_position()
  local direction = hero:get_direction()
  local beam = map:create_custom_entity{
    x=x, y=y-8, layer=z,
    width = 32, height = 32, direction = direction,
    sprite = "solforge_weapons/magic_sword_slash",
    model = "damaging_entity",
  }
  beam.damage = damage
  beam.duration = 2000
  local beam_sprite = beam:get_sprite()
  beam_sprite:set_animation"windup"

  sol.timer.start(map, 300, function()
    sol.audio.play_sound"sword1"
    hero:set_animation("sword_swing_forehand", function()
      item:set_finished()
    end)
    beam_sprite:set_animation("slash", function()
      beam:remove()
    end)
    --local sprite = beam:get_sprite()
    --sprite:set_direction(direction)
    --sol.timer.start(target, sprite:get_num_frames() * sprite:get_frame_delay(), function() beam:remove() end)
  end)
end)
