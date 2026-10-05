--[[
A little extra functionality around hero damage

NOTE!: If you don't use this, you WILL need to still call game:remove_life() somewhere,
since there are almost certainly other on_taking_damage registered events.
If this event is defined, the hero won't automatically take damage
--]]

local hero_meta = sol.main.get_metatable("hero")

hero_meta:register_event("on_taking_damage", function(hero, damage)
  local game = hero:get_game()
  --Make sure all attacks do at least 1 damage:
  if damage < 1 then
    damage = 1
  end

  --if this attack would kill you in 1 hit at above a certain percent of max life,
  --then let you survive with 1hp and play a scary sound
  --this function has a cooldown so it only happens occasionally
  local guts_save_percentage = .4
  local guts_save_cooldown = 60 * 1000
  if damage >= game:get_life()
  and game:get_life() >= game:get_max_life() * guts_save_percentage
  and damage >= game:get_max_life() * (1 - guts_save_percentage)
  and not game.guts_save_used then
    --leave you with 1hp
    damage = game:get_life() - 1
    sol.audio.play_sound"ohko"
    --set this mechanic on a cooldown
    game.guts_save_used = true
    sol.timer.start(game, guts_save_cooldown, function() game.guts_save_used = false end)
  elseif damage >= game:get_max_life() * .5 then
    sol.audio.play_sound"oh_lotsa_damage"
  end

  --Actually remove the life:
  game:remove_life(damage)

end)
