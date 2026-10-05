local enemy = ...
local game = enemy:get_game()
local map = enemy:get_map()
local hero = map:get_hero()
local sprite

local segments = {}
local position_buffer = {}

local NUM_SEGMENTS = 4 --this includes the head
local SPACING = 25
local MAX_BUFFER_SIZE = NUM_SEGMENTS * SPACING
local SPEED = math.rad(70)
local radius = 48
local radius_delta = 24

local life = 6
local damage = 1

function enemy:on_created()
  require("enemies/gooseberry_enemies/behavior/movement_circle_bounce"):apply(enemy)
  sprite = enemy:create_sprite("enemies/" .. enemy:get_breed())
  enemy:set_life(life)
  enemy:set_damage(damage)
  enemy:set_pushed_back_when_hurt(false)
  enemy:set_has_shadow()

  --the head is segment 1
  segments[1] = enemy
  --create legs
  local leg_breed = enemy:get_breed() .. "_segment"
  for i=2, NUM_SEGMENTS do
    local seg = enemy:create_enemy{
      name = "leg "..i,
      breed = leg_breed,
    }
    seg:set_life(life * life * life)
    seg:set_damage(damage)
    function seg:on_hurt()
      for _, seg in pairs(segments) do seg:hurt(1) end
    end
    segments[i] = seg
  end

end


function enemy:on_movement_changed(m)
  sprite:set_direction(m:get_direction4())
end


function enemy:on_restarted()
  local random_radius = radius + math.random(radius_delta * -1, radius_delta)
  local circumfrence = math.pi * 2 * random_radius
  local relative_speed = circumfrence / SPEED
  enemy:switch_movement(SPEED, random_radius)
end


function enemy:on_dying()
  for _, seg in pairs(segments) do
    seg:set_life(0)
  end
end


function enemy:on_position_changed(x, y, layer)
  sprite:set_direction( enemy:get_movement():get_direction4() )
  --save head's position
  local dir = enemy:get_sprite():get_direction()
  table.insert(position_buffer, 1, {x=x,y=y,layer=l,direction=dir})
  --move legs
  for i=2, NUM_SEGMENTS do
    local step_delay = SPACING * (i-1)
    if #position_buffer >= step_delay and segments[i] then
      local seg = segments[i]
      seg:set_position(position_buffer[step_delay].x, position_buffer[step_delay].y)
      if seg:get_movement() then
        seg:get_sprite():set_direction( seg:get_movement():get_direction4() )
      end
    end
  end
  if #position_buffer > MAX_BUFFER_SIZE then
    table.remove(position_buffer)
  end
end

