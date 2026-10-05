local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()
  local sprite = entity:get_sprite()
  sprite:set_opacity(0)
  
  if not entity:get_property("triggered") then
    sol.timer.start(10, function()
      entity:start_falling()
    end)
  else
    entity:add_collision_test("overlapping", function(entity,other)
      local other_type = other:get_type()
      if other_type == "hero" or other_type == "enemy" then
        entity.fall_speed = 400
        entity:start_falling()
      end
    end)
  end
end


function entity:start_falling()
  if entity.is_falling then return end
  entity.is_falling = true
  local fall_delay = entity.fall_delay or 10
  local fall_speed = entity.fall_speed or 500 --px/s
  local init_offset = entity.init_offset or 200 --how far above its landing point the boulder starts
  local destroy_sound = entity.destroy_sound or "breaking_stone"
  --you can set entity.destroy_sprite (a sprite when boulder shatters), or entity.destory_sprites(a table of sprites to play), or leave as default
  local destroy_sprites
  if entity.destroy_sprite then destroy_sprites = { entity.destroy_sprite }
  elseif entity.destroy_sprites then destroy_sprites = entity.destroy_sprites
  else destroy_sprites = { "entities/enemy_projectiles/dust_attack_big", "destructibles/cracked_rock" } end

  local sprite = entity:get_sprite()
  local shadow_sprite = entity:create_sprite("shadows/shadow_falling")

  --Smash into ground:
  local function smaaash()
    entity:remove_sprite(sprite)
    entity:remove_sprite(shadow_sprite)
    for _, id in pairs(destroy_sprites) do
      local dest_s = entity:create_sprite(id)
      if dest_s:has_animation("destroy") then dest_s:set_animation"destroy" end
    end
    sol.audio.play_sound(destroy_sound)
    entity:activate_collision()
    --remove self after a few seconds:
    sol.timer.start(entity, 4000, function()
      entity:remove()
    end)
  end

  --Start moving sprite:
  sol.timer.start(entity, fall_delay, function()
    sprite:set_opacity(255)
    sprite:set_xy(0, -1 * init_offset)
    local dist_traveled = 0
    sol.timer.start(entity, 50, function()
      local ox, oy = sprite:get_xy()
      oy = oy + (fall_speed / 20)
      dist_traveled = dist_traveled + oy
      sprite:set_xy(0, oy)
      if oy < 0 then
        return true
      else
        smaaash()
      end
    end)
  end)
end



function entity:activate_collision()
  local damage = entity.damage or 1
  local damage_type = entity.damage_type or "physical"
  local harmless_to_enemies = entity.harmless_to_enemies or false
  local harmless_to_hero = entity.harmless_to_hero or false

  entity.collided_entities = {}
  entity:add_collision_test("sprite", function(entity, other, sprite, other_sprite)
    --Hit enemies:
    if other:get_type() == "enemy" and not entity.harmless_to_enemies and not entity.collided_entities[other] then
      entity.collided_entities[other] = other
      if other.process_hit then
        other:process_hit({damage = damage, damage_type = damage_type})
      else
        other:hurt(damage)
      end

      if entity.collision_callback then
        entity:collision_callback(other)
      end

    --Hurt hero:
    elseif other:get_type() == "hero" and not entity.harmless_to_hero and not entity.collided_entities[other] then
      entity.collided_entities[other] = other
      if other.process_hit then
        other:process_hit({
          damage = damage,
          damage_type = damage_type,
        })
      else
        other:hurt(damage)
      end

      if entity.collision_callback then
        entity:collision_callback(other)
      end
    end
  end)
end
