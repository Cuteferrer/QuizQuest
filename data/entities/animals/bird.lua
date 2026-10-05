local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local flock_group_id

local fly_away_threshold = 64


function entity:on_created()
  --I was thinking birds could have a "flock group" ID, so they'd dly away together. But since they're flying away in the opposite direction of the hero, they'll generally be together anyway
  if not map.bird_flock_groups then map.bird_flock_groups = {} end
  flock_group_id = entity:get_property("flock_group")
  if flock_group_id then
    map.bird_flock_groups[flock_group_id].fly_away_angle = nil
  end

  entity:act_casual()
  entity:check_hero()
end


local function do_animation(id)
  local sprite = entity:get_sprite()
  if sprite:has_animation(id) then
    sprite:set_animation(id)
  end
end


function entity:act_casual()
  local sprite = entity:get_sprite()
  sprite:set_direction(math.random(0, 1))

  local function choose_action()
    local rand = math.random(1, 100)

    if entity.casual_action then
      do_animation("stopped")
    elseif rand <= 10 then
      sprite:set_direction((sprite:get_direction() + 1) % 2)
    elseif rand <= 20 then
      do_animation("pecking")
    elseif rand <= 30 then
      do_animation("peeking")
    elseif rand <= 40 then
      do_animation("stretching")
    elseif rand <= 50 then
      do_animation("rustle")
      sol.timer.start(entity, 1000, function() sprite:set_animation("stopped") end)
    else
      sprite:set_animation("stopped")
    end

    sol.timer.start(entity, math.random(500, 2000), function()
      choose_action()
    end)
  end

  choose_action()
end


function entity:check_hero()
  local hero = map:get_hero()
  if entity:get_distance(hero) <= fly_away_threshold then
    entity:fly_away()
  else
    local delay = math.random(80,150)
    sol.timer.start(entity, delay, function()
      entity:check_hero()
    end)
  end
end


function entity:fly_away()
  local sprite = entity:get_sprite()
  local hero = map:get_hero()
  local hero_angle = hero:get_angle(entity)
  local angle = (hero_angle > math.pi / 2 and hero_angle < 3 * math.pi / 2) and math.rad(140) or math.rad(40)
  sol.timer.stop_all(entity) --to prevent changing animation after starting to fly
  angle = angle + math.rad(math.random(-20, 20)) --add variance to fly away angles
  local m = sol.movement.create("straight")
  m:set_speed(200)
  m:set_ignore_obstacles(true)
  m:set_max_distance(800)
  m:set_angle(angle)
  m:start(entity, function()
    entity:remove()
  end)
  entity:set_layer(map:get_max_layer())
  sprite:set_direction((angle > math.pi / 2 and angle < 3 * math.pi / 2) and 1 or 0)
  sprite:set_animation("takeoff", function()
    sprite:set_animation("flying")
  end)
  sol.audio.play_sound("bird_flying_away")
end


