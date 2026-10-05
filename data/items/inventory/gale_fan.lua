local item = ...
local game = item:get_game()

local charge_time = 250
local num_twisters = 3
local range = 32
local spread = math.rad(60)


function item:on_started()
  item:set_savegame_variable("possession_gale_jar")
  item:set_assignable(true)
  item:set_ammo"_magic"
end

function item:on_using()
  if item:try_spend_ammo(20) then
    local map = item:get_map()
    local hero = map:get_hero()
    local direction = hero:get_direction()

    hero:set_animation("charging")
    sol.timer.start(hero, charge_time, function()
      hero:set_animation("hookshot")
      sol.timer.start(hero, 100, function()
        item:set_finished()
      end)
      local x, y, z = hero:get_position()
      for i = 1, num_twisters do
        local twister = map:create_custom_entity{
          x= x + game:dx(24)[direction], y= y + game:dy(24)[direction], layer=z,
          width=16, height=16, direction=0,
          model="elements/twister", sprite = "elements/twister",
        }
        local m = sol.movement.create"straight"
        local angle = (direction * math.pi / 2) - spread / 2 + ((spread / (num_twisters - 1)) * (i - 1))
        m:set_angle(angle)
        m:set_speed(80)
        m:set_smooth(false)
        m:set_max_distance(range)
        m:start(twister)
        twister:set_duration(600)
        function twister:on_collision_enemy(enemy)
          enemy:immobilize(1500)
          local m =  sol.movement.create"straight"
          m:set_angle(hero:get_angle(enemy))
          m:set_speed(100)
          m:set_max_distance(48)
          m:start(enemy)
        end
      end
    end)
  else --no magic
    item:set_finished()
  end
end
