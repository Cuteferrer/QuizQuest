--[[
Created by Max Mraz, licensed MIT
Automatically makes the hero "fall" when teleporting to a new map via a hole
--]]

local fall_maps = {}

local tele_meta = sol.main.get_metatable("teletransporter")
local dest_meta = sol.main.get_metatable("destination")
local hero_meta = sol.main.get_metatable"hero"


local function play_landing_animation(hero)
  hero:freeze()
  hero:set_direction(3)
  sol.timer.start(hero:get_map(), 550, function()
    sol.audio.play_sound"hero_falls"
  end)
  hero:set_visible(false)
  --wait a beat, because destination:on_activated is called before map:on_opening_transition_finished,
  -- and that second event automatically calls hero:unfreeze, which resets the hero's animation to "stopped"
  sol.timer.start(sol.main.get_game(), 700, function()
    hero:freeze()
    hero:set_animation"dash"
    hero:set_visible(true)
    hero:fall({
      callback = function()
        sol.audio.play_sound"hero_lands"
        hero:set_animation("landing", function()
          hero:unfreeze()
        end)
      end
    })
  end)
end


tele_meta:register_event("on_activated", function(tele, hero)
  local ground = hero:get_ground_below()
  if ground == "hole" then
    fall_maps[tele:get_destination_map()] = tele:get_destination_name()
  end
end)

dest_meta:register_event("on_activated", function(dest, hero)
  if fall_maps[dest:get_map():get_id()] == dest:get_name() then
    play_landing_animation(hero)
  end
end)


function hero_meta:hole_drop_landing()
  play_landing_animation(self)
end

