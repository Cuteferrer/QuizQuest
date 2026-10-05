local entity = ...
local game = entity:get_game()
local map = entity:get_map()

local collision_damage = 10


function entity:on_created()
  local sprite = entity:get_sprite()
  entity:set_drawn_in_y_order(true)

  --Burst when hitting hero:
  entity:add_collision_test("sprite", function(entity, other)
    if other:get_type() == "hero" and other:get_can_be_hurt() and entity:overlaps(other) then
      entity:burst()
      --Damage hero a little when hitting them:
      sol.audio.play_sound("hero_hurt_small")
      other:blood_splatter(self, 8)
      game:remove_life(collision_damage)
    end
  end)

  --allows tumbleweeds to blow toward the hero if he's in range:
  entity:prepare_to_blow()
end


function entity:react_to_solforge_weapon()
  entity:burst()
end

function entity:react_to_fire()
  entity:burst()
end

function entity:react_to_bullet()
  entity:burst()
end

function entity:process_hit()
  entity:burst()
end

function entity:react_to_hookshot()
  entity:burst()
end



function entity:burst()
  if entity.has_burst then return end
  entity.has_burst = true
  entity:clear_collision_tests()
  entity:make_sound"foliage_destroy"
  local sprite = entity:get_sprite()
  sprite:set_animation("bursting", function()
    entity:remove()
  end)

  --Create noxious gas:
  local x, y, z = entity:get_position()
  local gas = map:create_custom_entity{
    x=x, y=y, layer=z, width=16, height=16, direction=0,
    model = "attacks/status_cloud",
    sprite = "items/cloud",
  }
  local gas_sprite = gas:get_sprite()
  gas_sprite:set_color_modulation({190,255,190,255})
  gas.duration = 1200
  gas.status_type = nil
  gas.status_frequency = 600
  gas.hero_damage_amount = 5
  gas.enemy_damage_amount = 3
end


function entity:prepare_to_blow()
  local hero = map:get_hero()
  sol.timer.start(entity, 1000, function()
    if entity.anchored then return end
    local random = math.random(1, 100)
    local x, y, z = entity:get_position()
    local hx, hy, hz = hero:get_position()
    if (entity:get_distance(hero) <= 200) and (math.abs(hy - y) <= 24)  and (random < 20) then
      entity:blow_toward_hero()
    elseif entity:get_distance(hero) < 150 and random < 5 then
      entity:blow_toward_hero()
    else
      return true --repeat timer
    end
  end)
end


function entity:blow_toward_hero()
  local hero = map:get_hero()
  local sprite = entity:get_sprite()
  sprite:set_animation("rolling")

  local m = sol.movement.create"straight"
  local angle = entity:get_angle(hero)
  local direction = (angle > math.pi / 2 and angle < 3 * math.pi / 2) and 1 or 0
  sprite:set_direction(direction)
  m:set_angle(direction * math.pi)
  m:set_speed(65)
  m:start(entity)

  function m:on_obstacle_reached()
    m:stop()
    entity:burst()
  end
end
