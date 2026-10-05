--[[
Created by Max Mraz, licensed MIT

Checkpoint (campfire) actions

For any entity to execute some arbitrary action when the player rests at a checkpoint (as long as they're on the same map), have that entity call
map:register_checkpoint_callback(entity, callback)

This will result in this code:
callback(entity)
being called for any map entities that have registered. This is useful to allow entities to reset themselves when the player rests at a checkpoint

--]]


local game_meta = sol.main.get_metatable"game"
local map_meta = sol.main.get_metatable"map"

function game_meta:save_checkpoint(x, y, z)
  local game = self
  local hero = game:get_hero()
  if not (x and y and z) then
    x, y, z = hero:get_position()
  end
  game:set_value("checkpoint_map", game:get_map():get_id())
  game:set_value("checkpoint_x", x)
  game:set_value("checkpoint_y", y)
  game:set_value("checkpoint_z", z)
end


function game_meta:refill_respawn_items()
  local game = self
  for k, item in pairs(game.fill_on_checkpoint_items) do
    item:set_amount(item:get_max_amount())
  end
end


function game_meta:checkpoint_full_heal()
  local game = self
  local hero = game:get_hero()
  game:set_life(game:get_max_life())
  game:set_magic(game:get_max_magic())
  hero:cure_all_status_effects()
  hero:clear_all_status_buildup()
end


function game_meta:respawn_at_checkpoint(callback)
  --Called when respawning after dying, or when sitting at a checkpoint, or when starting a new game
  local game = self
  local hero = game:get_hero()
  game:save()
  local checkpoint_map = game:get_value"checkpoint_map"
  if not checkpoint_map then return end
  game:set_suspended(true)
  sol.timer.start(sol.main, 601, function()
    hero:set_position(16,16,0) --this is to prevent you from teleporting to the checkpoint map outside its bounds
    hero:teleport(checkpoint_map, "_same", "immediate")
    sol.timer.start(game,20,function()
      local x, y, z = game:get_value"checkpoint_x", game:get_value"checkpoint_y", game:get_value"checkpoint_z"
      hero:set_position(x, y, z)
      local camera = hero:get_map():get_camera()
      camera:set_position(camera:get_position_to_track(x, y, z))
    end)
    hero:set_direction(3)
    game:checkpoint_full_heal()
    game:refill_respawn_items()
    game:get_map():respawn_enemies() --need to do this, otherwise you can save/quit for a full heal without respawning enemies
    if callback then callback() end
  end)

end


function map_meta:clear_map_projectiles_and_stuff()
  --When resting at a checkpoint, remove any flying bullets or other enemy attacks
  local map = self
  for e in map:get_entities_by_type("custom_entity") do
    if e:get_model():match("enemy_projectiles/") then
      e:remove()
    end
  end
end


--[[
Register Checkpoint Callback - this can be used in two ways:
1- Loose callback
Call:
map:register_checkpoint_callback(function() map:do_something end)
to register a callback without an entity key.
These cannot take arguments, and cannot be un-registered (but are scoped to the map object so you know, not immortal)

2- Callback keyed to an entity
Entities to reset themselves on resting at a checkpoint. An entity might call:
map:register_checkpoint_callback(trap, function() trap:reset end)
to reset itself on resting at a checkpoint
--]]
function map_meta:register_checkpoint_callback(entity, callback)
  local map = self
  if not map.checkpoint_callbacks then map.checkpoint_callbacks = {} end
  if not map.checkpoint_callback_entities then map.checkpoint_callback_entities = {} end
  if type(entity) == "function" then
    callback = entity
    entity = nil
    table.insert(map.checkpoint_callbacks, callback)
  elseif entity then
    map.checkpoint_callback_entities[entity] = callback
  end
end


function map_meta:unregister_checkpoint_callback(entity)
  local map = self
  map.checkpoint_callback_entities[entity] = nil
end


function map_meta:trigger_checkpoint_callbacks()
  local map = self
  if not map.checkpoint_callbacks then map.checkpoint_callbacks = {} end
  if not map.checkpoint_callback_entities then map.checkpoint_callback_entities = {} end
  for _, callback in pairs(map.checkpoint_callbacks) do
    callback()
  end
  for entity, callback in pairs(map.checkpoint_callback_entities) do
    if not entity:exists() then
      map.checkpoint_callback_entities[entity] = nil --remove from table
    end
    callback(entity)
  end
end

