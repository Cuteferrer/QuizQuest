--[[
Created by Max Mrazm, Licensed MIT

Usage: require("items/charms/charm_manager")

For any events you want charms to be able to react to, add the line:
game.charm_manager:trigger_event("event_name", ...)

Then for charms that you'd like to react to that charm, add:
game.charm_manager:subscribe("event_name", function(...)
  if game:get_value("this_charm_is_equipped") then
    --execute some code in respone to the event
  end
end)

All charms that have registered against that event will be triggered, whether or not they're equipped, so make sure your callback checks
Note: trigger_event can take an arbitrary number of arguments after event_name, and will pass them along to the callback functions

Equipped charms are accessible from game.equipped_charms
The equipped_charms table has keys which are the item's name, and a value which is an item userdata:
game.equipped_charms = {
  "charms/warrior_magic" = itemUserdata,
  "charms/gradual_heal" = itemUserdata,
  "charms/battlemage" = itemUserdata,
}
--]]

local manager = {}
local events = {}

function manager:get_events()
  return events
end

function manager:set_events(new_events)
  events = new_events
end

--Allow charm manager to be accessible as game.charm_manager
local game_meta = sol.main.get_metatable("game")
game_meta.charm_manager = manager

game_meta:register_event("on_started", function(game)
  --Set default charm limit, if not already defined
  if not game:get_value("charm_slots") then
    game:set_value("charm_slots", 4)
  end

  --Set up game.equipped_charms table from savegave data:
  game.equipped_charms = {}
  local saved_charms = game:get_table_value("equipped_charms")
  if not saved_charms then saved_charms = {} end
  for item_name, _ in pairs(saved_charms) do
    local item = game:get_item(item_name)
    game.equipped_charms[item_name] = item
    --Trigger charm activation, if necessary
    if item.on_activated then item:on_activated() end
  end
end)


function game_meta:is_charm_equipped(charm_name)
  assert(self.equipped_charms, "game.equipped_charms table is nil - something has gone wrong")
  if self.equipped_charms[charm_name] then
    return true
  else
    return false
  end
end


function manager:equip_charm(item_name)
  local game = sol.main.get_game()
  local item = game:get_item(item_name)
  local charm_slots_limit = game:get_value("charm_slots") or 4
  local charm_slots_used = game:get_value("charm_slots_used") or 0
  local cost = item.charm_cost

  --Check if the charm costs too much to equip
  if charm_slots_used + cost > charm_slots_limit then
    sol.audio.play_sound"wrong"
    return
  end

  game.equipped_charms[item_name] = item
  game:set_table_value("equipped_charms", game.equipped_charms)
  sol.audio.play_sound"charm_equip"
  --Preform activation
  if item.on_equipped then item:on_equipped() end
  if item.on_activated then item:on_activated() end
  --Fill charm slots
  game:set_value("charm_slots_used", charm_slots_used + cost)
end


function manager:unequip_charm(item_name)
  local game = sol.main.get_game()
  local item = game:get_item(item_name)
  local charm_slots_limit = game:get_value("charm_slots") or 4
  local charm_slots_used = game:get_value("charm_slots_used") or 0
  local cost = item.charm_cost

  game.equipped_charms[item_name] = nil
  assert(game.equipped_charms[item_name] == nil, "didn't remove correctly")
  game:set_table_value("equipped_charms", game.equipped_charms)
  sol.audio.play_sound"charm_unequip"
  --Preform deactivation event
  if item.on_unequipped then item:on_unequipped() end
  --Lower charm slots used
  local cost = item.charm_cost
  game:set_value("charm_slots_used", charm_slots_used - cost)
end


function manager:subscribe(event_name, callback)
  if not events[event_name] then events[event_name] = {} end
  table.insert(events[event_name], callback)
end


function manager:trigger_event(event_name, ...)
  if not events[event_name] then
    --Don't try to trigger an event if nothing has registered a callback for it:
    return
  end
  for k, callback in pairs(events[event_name]) do
    callback(...)
  end
end


return manager

