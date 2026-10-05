--[[
Created by Max Mraz, licensed MIT
Automatically scales several enemy stats by map name
Adds a value: enemy.level to every enemy, which is the area level. This level scales damage, life, exp, and money dropped.

Note: to overwrite this for any enemy, give the enemy a property called "level", which will set the enemy's level, ignoring area level
This overwrite is useful if you want a tougher enemy in a lower-level area.
--]]

local map_meta = sol.main.get_metatable"map"
local enemy_meta = sol.main.get_metatable"enemy"
local area_level_config = require("scripts/modules/trillium_config/world_data/area_level_config")
local stat_constants = require("scripts/modules/trillium_config/world_data/area_level_scaling")



--Life
local function adjust_life(enemy)
  local base_life = enemy.max_life or enemy:get_life()
  local multiplier = stat_constants.ENEMY_LEVEL_SCALING_LIFE_RATE * (enemy.level - 10)
  local new_life = base_life + (base_life * multiplier)
  enemy.max_life = new_life
  enemy:set_life(new_life)
end

--Money
local function adjust_money(enemy)
  enemy.money = enemy.money + (enemy.money * .10 * (enemy.level - 10))
end


--Damage
local function adjust_damage(enemy)
  --print(enemy:get_breed())
  local multiplier = stat_constants.ENEMY_LEVEL_SCALING_DAMAGE_RATE * (enemy.level - 10)
  enemy.base_damage = enemy.base_damage + (enemy.base_damage * multiplier)
end

local function adjust_exp(enemy)
  local level_multiplier = 7077898 + (-7077896.94871) / (1 + (enemy.level / 12681.42)^2.391309) --this is how you do math I guess
  local new_exp = enemy.exp * level_multiplier
  enemy.exp = new_exp
end


--This is for the more if you want the enemy level to match the hero level:
--[[
--Life:
local function adjust_life(enemy)
  local base_life = enemy.max_life or enemy:get_life()
  local multiplier = stat_constants.ENEMY_LEVEL_SCALING_LIFE_RATE * (enemy.level - 10)
  local new_life = base_life + (base_life * multiplier)
  enemy.max_life = new_life
  enemy:set_life(new_life)
end


--Exp
local function adjust_exp(enemy)
  local level_multiplier = 7077898 + (-7077896.94871) / (1 + (enemy.level / 12681.42)^2.391309) --this is how you do math I guess
  local new_exp = enemy.exp * level_multiplier
  enemy.exp = new_exp
end



--Money
local function adjust_money(enemy)
  enemy.money = enemy.money + (enemy.money * .10 * (enemy.level - 10))
end


--Damage
local function adjust_damage(enemy)
  --print(enemy:get_breed())
  local multiplier = stat_constants.ENEMY_LEVEL_SCALING_DAMAGE_RATE * (enemy.level - 10)
  enemy.base_damage = enemy.base_damage + (enemy.base_damage * multiplier)
end
--]]


--Get area level based on map ID:
local function get_area_level(map)
  local area_level = nil
  if map.area_level then
    --Just a note: this doesn't work when enemies are first created on a map, only when created dynamically
    --So, respawning at a campfire, etc
    --Reason being, the map script hasn't run yet when enemies first call their on_created() event
    area_level = map.area_level
  else
    for _, area_config in ipairs(area_level_config) do
      if map:get_id():match(area_config.prefix) then
        area_level = area_config.level
        break
      end
    end
  end
  if not area_level then --fallback in case the map isn't in the prefix table
    area_level = 10
    error("Warning: area_level is undefined for map: '" .. map:get_id() .. "' - please check 'level_up/area_level_config.lua' script to ensure it wasn't missed.")
  end

  return area_level
end



map_meta:register_event("on_started", function(map)
  --Have each map set its area level, even though enemies won't reference that
  map.area_level = get_area_level(map)
end)


function enemy_meta:scale_to_area_level()
  local enemy = self
  local map = enemy:get_map()
  local area_level = get_area_level(map)
  if enemy.level then
    --level already set
  elseif enemy:get_property"level" then
    enemy.level = enemy:get_property"level"
  else
    enemy.level = area_level
  end
  adjust_life(enemy)
  adjust_exp(enemy)
  adjust_money(enemy)
  adjust_damage(enemy)
end


--[[ --This is handled when the enemy is created by the behavior_applicator. And you don't want to call it twice or enemies will double-scale lol
enemy_meta:register_event("on_created", function(enemy)
  enemy:scale_to_area_level()
end)
--]]

