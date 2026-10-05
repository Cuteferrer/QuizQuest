local manager = {}

--Make manager accessible to other scripts:
--Call with sol.all_entities_manager:apply_to_entities(name, fn)
sol.all_entities_manager = manager

local metas = {
  sol.main.get_metatable"hero",
  sol.main.get_metatable"dynamic_tile",
  sol.main.get_metatable"teletransporter",
  sol.main.get_metatable"destination",
  sol.main.get_metatable"pickable",
  sol.main.get_metatable"destructible",
  sol.main.get_metatable"carried_object",
  sol.main.get_metatable"chest",
  sol.main.get_metatable"shop_treasure",
  sol.main.get_metatable"enemy",
  sol.main.get_metatable"npc",
  sol.main.get_metatable"block",
  sol.main.get_metatable"jumper",
  sol.main.get_metatable"switch",
  sol.main.get_metatable"sensor",
  sol.main.get_metatable"separator",
  sol.main.get_metatable"wall",
  sol.main.get_metatable"crystal",
  sol.main.get_metatable"crystal_block",
  sol.main.get_metatable"stream",
  sol.main.get_metatable"door",
  sol.main.get_metatable"stairs",
  sol.main.get_metatable"bomb",
  sol.main.get_metatable"explosion",
  sol.main.get_metatable"fire",
  sol.main.get_metatable"arrow",
  sol.main.get_metatable"hookshot",
  sol.main.get_metatable"boomerang",
  sol.main.get_metatable"camera",
  sol.main.get_metatable"custom_entity",
}


local entity_methods = {

  --Make Sound
  --Plays a sound effect that is automatically attenuated based on the entity's proximity to the hero
  make_sound = function(entity, sound_id, falloff_rate)
    --NOTE: falloff rate affects how much the sound is affected by distance to hero.
    --Higher numbers mean the sound will carry further
    --A falloff rate of 1 means 1% sound drop per pixel to hero, silence after 100px
    --A falloff rate of 5 means 0.2% sound drop per pixel to hero, silence after 500px
    local map = entity:get_map()
    local hero = map:get_hero()
    --Don't bother if the entity is in a different region:
    if not entity:is_in_same_region(hero) then return end
    falloff_rate = falloff_rate or 3
    local distance = entity:get_distance(hero)
    local sfx = sol.sound.create(sound_id)
    local max_volume = sol.audio.get_sound_volume()
    local vol = 100 - (distance / falloff_rate)
    if vol <= 0 then return end
    sfx:set_volume(vol)
    if vol > 0 then sfx:play() end
  end,

  --Has LOM
  --Returns whether the entity has a straight line it can move in to a target entity or to {x,y,z} coordinates
  has_lom = function(entity, tx, ty, tz) --Takes X,Y, Z or some other entity as target. Example: enemy:has_lom(hero) or enemy:has_lom(x, y, z)
    if type(tx) ~= "number" then --assume an entity was passed as the target
      tx, ty, tz = tx:get_position()
    end
    local lom = true
    local map = entity:get_map()
    local x, y, z = entity:get_position()
    local dx, dy = 0, 0
    local distance = entity:get_distance(tx, ty)
    local angle = entity:get_angle(tx, ty)
    if entity:get_layer() ~= z then return false end --if you're not on the same layer, cannot move to the other entity
    for i=0, distance do
      dx, dy = math.floor(math.cos(angle)*i), -math.floor(math.sin(angle)*i)
      local obstacle = entity:test_obstacles(dx, dy)
      if obstacle then
        lom = false
        break
      end
    end
    return lom
  end,


  --Returns whether given entity is directly on top of other entity, or if there's another entity separating them
  is_directly_atop = function(entity, other)
    local map = entity:get_map()
    local checking_in_between = false
    local atop = false
    for e in map:get_entities_in_rectangle(entity:get_bounding_box()) do
      if e == other then
        checking_in_between = true
      elseif e == entity then
        checking_in_between = false
        atop = true
        break
      elseif checking_in_between then
        local mod_ground = e:get_modified_ground()
        if (mod_ground == "traversable") or (mod_ground == "ladder") or (mod_ground == "shallow_water") or (mod_ground == "grass") or (mod_ground == "ice") then
          if e:is_enabled() then
            atop = false
            break --don't let it get to the checking entity, there's some ground in between the checked entity and it
          end
        end
      end
    end
    return atop
  end,


  --Adds sparkles on an entity to draw attention to it on the map
  start_sparkle = function(entity, config)
    config = config or {}
    if config.should_sparkle then assert(type(config.should_sparkle) == "function", "If passing a config.should_sparkle value, it needs to be a function") end
    local freq = config.freq or 1200
    local freq_variance = config.freq_variance or 300
    local height = config.height or 12
    local height_variance = config.height_variance or 12
    local width_variance = config.width_variance or 8
    local should_fn = config.should_sparkle or function() return true end
    sol.timer.start(entity, 100, function()
      if should_fn() then
        local sparkle = entity:create_sprite("entities/sparkle")
        sparkle:set_xy(
          math.random(width_variance * -1, width_variance),
          math.random(height - height_variance, height + height_variance) * -1
        )
        sol.timer.start(entity, 500, function()
          entity:remove_sprite(sparkle)
        end)
        return math.random(freq - freq_variance, freq + freq_variance)
      end
    end)
  end,

}


local function apply_function(k, fn)
  for _, meta in pairs(metas) do
    meta[k] = fn
  end
end


for k, fn in pairs(entity_methods) do
  apply_function(k, fn)
end


function manager.apply_to_entities(name, fn)
  apply_function(name, fn)
end


return manager
