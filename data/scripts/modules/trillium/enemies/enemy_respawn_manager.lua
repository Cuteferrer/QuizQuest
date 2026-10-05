--[[
Created by Max Mraz, licensed MIT
Sets up a Dark Souls style respawn system for enemies. Enemies will not respawn unless you die, or map:respawn_enemies() is called
Enemies can ignore this (and respawn whenever you leave/come back to the map) by setting enemy.respawn_manager_ignore = true
--]]

local map_meta = sol.main.get_metatable"map"
local game_meta = sol.main.get_metatable"game"
local enemy_meta = sol.main.get_metatable"enemy"

local manager = {}

local master_enemy_table = {} --keeps track of which enemies are killed


game_meta:register_event("on_started", function(self)
  --Note: we lazy-load to the master enemy table as needed:
  master_enemy_table = {}
end)

local function get_map_key(map_id)
  return "respawn_enemy_table_" .. map_id:gsub("/", "_")
end

local function get_map_keys_with_enemy_data()
  local game = sol.main.get_game()
  return game:get_table_value("respawn_maps_list") or {}
end

local function save_map_enemy_state(map_id)
  local game = sol.main.get_game()
  local key = get_map_key(map_id)
  game:set_table_value(key, master_enemy_table[map_id] or {})
  --Mark that this map has enemy state data on it:
  local touched_map_keys = get_map_keys_with_enemy_data()
  touched_map_keys[key] = true
  game:set_table_value("respawn_maps_list", touched_map_keys)
end

local function load_map_enemy_state(map_id)
  local game = sol.main.get_game()
  local key = get_map_key(map_id)
  master_enemy_table[map_id] = game:get_table_value(key) or {}
end

--Clear all enemies' states from savegame
local function reset_enemy_table()
  local game = sol.main.get_game()
  local touched_map_keys = get_map_keys_with_enemy_data()
  for key, _ in pairs(touched_map_keys) do
    game:set_value(key, nil)
  end
  game:set_table_value("respawn_maps_list", {})
  master_enemy_table = {}
end

--Make enemy mark on table when it is killed:
local function init_respawn_on_death(enemy, map_id, cid)
  enemy:register_event("on_dying", function()
    if enemy.respawn_manager_ignore then return end
    master_enemy_table[map_id][cid] = true
    --NOTE: if you always respawn enemies when loading a saved game, this call is redundant
    --However, I want to leave it in unless is causes performance problems, because
    --the theory you COULD load a save mid-map and pick up where you saved
    save_map_enemy_state(map_id)
  end)
end


--Save state of this map's enemies to the savegame
function map_meta:save_enemy_respawn_table()
  save_map_enemy_state(self:get_id())
end


--Set up respawn system for this map's enemies
function map_meta:manage_enemy_respawns() --called on map:on_started
  local map = self
  local map_id = map:get_id()

  --load map's killed enemies list if needed
  if not master_enemy_table[map_id] then
    load_map_enemy_state(map_id)
  end

  for enemy in map:get_entities_by_type("enemy") do
    if not enemy.respawn_do_not_index then
      local x, y, layer = enemy:get_position()
      local breed = enemy:get_breed()
      local cid = x .. "," .. y .. "," .. layer .. "," .. breed
      init_respawn_on_death(enemy, map_id, cid)
      --if enemy has already been killed, remove it
      if master_enemy_table[map_id][cid] then
        enemy:remove()
      end
    end
  end

end


--Respawn enemies on this map
function map_meta:respawn_enemies()
  local map = self
  local map_id = map:get_id()
  --Clear enemy state across the game:
  reset_enemy_table()
  master_enemy_table[map_id] = {}
  --Remove all enemies from the map
  for enemy in map:get_entities_by_type("enemy") do
    --remove any weapons they might be using:
    if enemy.attack_entities then
      for _, weapon_entity in pairs(enemy.attack_entities) do weapon_entity:remove() end
    end
    enemy:remove()
  end
  --Recreate enemies from map.dat file:
  sol.timer.start(map, 10, function()
    local env = setmetatable({}, {__index = function() return function() end end})
    function env.enemy(props)
      local created_enemy = map:create_enemy{
        name = props.name,
        x = props.x, y = props.y, layer = props.layer,
        direction = props.direction,
        breed = props.breed,
        savegame_variable = props.savegame_variable,
        treasure_name = props.treasure_name,
        treasure_variant = props.treasure_variant,
        treasure_savegame_variable = props.treasure_savegame_variable,
        enabled_at_start = props.enabled_at_start,
        properties = props.properties,
      }
      --If savegame variable exists and is already set to true (for bosses you've killed already, etc) then created_enemy will be nil
      if created_enemy then
        local x, y, layer = props.x, props.y, props.layer
        local breed = props.breed
        local cid = x .. "," .. y .. "," .. layer .. "," .. breed
        -- Re-register the death handler
        init_respawn_on_death(created_enemy, map_id, cid)
      end
    end

    local chunk = sol.main.load_file("maps/" .. map_id .. ".dat")
    setfenv(chunk, env)
    chunk()
  end)

  save_map_enemy_state(map_id)

end


map_meta:register_event("on_started", function(self)
  self:manage_enemy_respawns()
end)

map_meta:register_event("on_finished", function(self)
  --save enemy state when leaving a map:
  --this is probably redundant if each enemy trigger a state save whenever it dies
  save_map_enemy_state(self:get_id())
end)


game_meta:register_event("on_game_over_started", function(self)
  reset_enemy_table()
end)


