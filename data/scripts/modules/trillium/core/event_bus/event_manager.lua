--[[
Created by Max Mraz, Licensed MIT
Event pub/sub system for systems to publish or listen for events

To publish an event:
game.event_manager:trigger_event("event_name", ...)

Then for when you'd like to react to that event, add:
game.event_manager:subscribe("event_name", function(...)
  if game:get_value("this_charm_is_equipped") then
    --execute some code in respone to the event
  end
end)

Note: trigger_event can take an arbitrary number of arguments after event_name, and will pass them along to the callback functions
--]]

local manager = {}
local events = {}

function manager:get_events()
  return events
end

function manager:set_events(new_events)
  events = new_events
end

--Allow manager to be accessible as game.event_manager
local game_meta = sol.main.get_metatable("game")
game_meta.event_manager = manager


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

