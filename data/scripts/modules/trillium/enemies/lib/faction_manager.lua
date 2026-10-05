local enemy_meta = sol.main.get_metatable"enemy"

local faction_enemy_config =require("scripts/modules/trillium/enemies/lib/faction_config")

enemy_meta:register_event("on_created", function(enemy)
  if enemy:get_property("faction") then
    enemy.faction = enemy:get_property("faction")
  end
end)


function enemy_meta:is_hostile_to(other)
  local enemy = self
  local hostile_factions = enemy.faction and faction_enemy_config[enemy.faction] or {}
  local other_type = other:get_type()
  local is_hostile = false

  if enemy.faction == "hero" then --behavior of allies
    if other_type == "hero" then is_hostile = false
    elseif other_type == "enemy" then is_hostile = true
    end
  else --behavior of enemies
    if other_type == "hero" then is_hostile = true
    elseif other.faction == "hero" then is_hostile = true
    elseif hostile_factions[other.faction] then is_hostile = true
    end
  end

  return is_hostile
end


function enemy_meta:can_target(other)
  local enemy = self
  local can_target = false
  local other_type = other:get_type()
  if other == self then
    can_target = false --Stop hitting yourself!
  elseif not other:is_enabled() then can_target = false --can't target someone not enabled
  elseif (not enemy:is_in_same_region(other)) or (enemy:get_layer() ~= other:get_layer()) or (enemy:get_distance(other) > (enemy.abandon_hero_distance or 400)) then
    can_target = false --Can't go after someone you can't get to
  elseif (other_type == "hero") or (other_type == "enemy") then
    can_target = enemy:is_hostile_to(other)
  end

  return can_target
end



function enemy_meta:choose_faction_target()
  local enemy = self
  local map = enemy:get_map()
  local hero = map:get_hero()
  local target

  if enemy.faction == "hero" then
    --Hero allies, special logic:
    for e in map:get_entities_by_type("enemy") do
      if not enemy:can_target(e) then --do nothing, if you can't target this enemy
      elseif not target then
        target = e
      elseif enemy:get_distance(e) < enemy:get_distance(target) then
        target = e
      end
    end

  else
    --Choose target from enemy factions or hero:
    --Closest enemy:
    for e in map:get_entities_by_type("enemy") do
      if not enemy:can_target(e) then --do nothing, if you can't target this enemy
      elseif not target then
        target = e
      elseif enemy:get_distance(e) < enemy:get_distance(target) then
        target = e
      end
    end
    --Closest hero:
    for h in map:get_entities_by_type("hero") do
      if not enemy:can_target(h) then --do nothing, if you can't target this hero
      elseif not target then
        target = h
      elseif enemy:get_distance(h) < enemy:get_distance(target) then
        target = h
      end
    end

  end

  return target
end



